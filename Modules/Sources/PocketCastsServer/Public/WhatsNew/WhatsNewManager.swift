import Foundation
import PocketCastsUtils

/// Keeps the What's New catalog in memory and up to date, along with what the user has read of it.
///
/// The catalog is one small file published for the whole platform, so the app works from the last
/// copy it fetched rather than from a request: the feed opens on the messages it already has
/// instead of a spinner, and anything deriving state from the feed — the dots on Profile —
/// can answer without waiting on the network.
///
/// Refreshing is driven by the app becoming active, which covers a cold launch and every return
/// from the background, and throttled by how old the copy on disk is. A timer would keep firing
/// against a file that changes a few times a month, and refreshing only at launch would leave a
/// user who never quits the app on whatever was published the day they installed it.
///
/// Read state is kept in a file, and is read back before the first catalog is published, so a
/// message read in an earlier session never shows up unread, even for a moment. Signed in, that
/// file and the account are reconciled on every refresh and whenever a message is read, so the feed
/// works from what the user has read on any of their devices.
@MainActor
public final class WhatsNewManager: ObservableObject {
    nonisolated public static let shared = WhatsNewManager()

    /// The catalog the app is working from: the last copy fetched, read back from disk on the first
    /// refresh of the session.
    @Published public private(set) var catalog: WhatsNewCatalog?

    /// Which messages the user has read, which the feed and the Profile tab have already pointed
    /// them at, and which polls the user answered.
    @Published public private(set) var readState = WhatsNewReadState()

    /// How long a fetched catalog is treated as current before the next foreground replaces it.
    nonisolated public static let refreshInterval: TimeInterval = 6.hours

    nonisolated private let task: WhatsNewCatalogTask
    nonisolated private let readStateStore: WhatsNewReadStateStore
    nonisolated private let readStateTask: WhatsNewReadStateTask
    nonisolated private let userDefaults: UserDefaults
    private let refreshInterval: TimeInterval
    private var refreshTask: Task<Void, Never>?
    private var isRefreshForced = false
    private var hasLoadedReadState = false
    private var syncTask: Task<Void, Never>?
    private var isSyncPending = false

    nonisolated public init(task: WhatsNewCatalogTask = WhatsNewCatalogTask(),
                            readStateStore: WhatsNewReadStateStore = WhatsNewReadStateStore(),
                            readStateTask: WhatsNewReadStateTask = WhatsNewReadStateTask(),
                            userDefaults: UserDefaults = .standard,
                            refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) {
        self.task = task
        self.readStateStore = readStateStore
        self.readStateTask = readStateTask
        self.userDefaults = userDefaults
        self.refreshInterval = refreshInterval
    }

    /// Publishes the catalog the app already has, and fetches a new one when that copy has aged out.
    ///
    /// Meant to be called every time the app becomes active: overlapping calls share one request,
    /// and the network is only reached once the cached copy is older than the refresh interval.
    @discardableResult
    public func refreshIfNeeded() -> Task<Void, Never> {
        if let refreshTask { return refreshTask }

        let refreshTask = Task { [weak self] in
            await self?.performRefresh()
            self?.refreshTask = nil
            self?.isRefreshForced = false
        }
        self.refreshTask = refreshTask
        return refreshTask
    }

    /// Fetches the catalog however recently the copy on disk was written, for when the user asks
    /// for the latest messages, such as by pulling to refresh the feed.
    ///
    /// Joins a refresh already in flight, making sure it reaches the network.
    @discardableResult
    public func refresh() -> Task<Void, Never> {
        isRefreshForced = true
        return refreshIfNeeded()
    }

    /// Marks messages read, whether the user opened one or cleared the feed with "Read all".
    public func markAsRead(_ messageIDs: some Sequence<String>) {
        if updateReadState({ $0.readMessageIDs.formUnion(messageIDs) }) {
            syncReadState()
        }
    }

    /// Marks messages unread again, here and for the account, so the user can come back to one.
    ///
    /// What the dots have pointed at is left alone: the user asked for the message back in the feed,
    /// not for Profile to start pointing at it again.
    @discardableResult
    public func markAsUnread(_ messageIDs: some Sequence<String>) -> Task<Void, Never> {
        let messageIDs = Set(messageIDs)
        guard updateReadState({ $0.readMessageIDs.subtract(messageIDs) }) else { return Task {} }

        return Task { [readStateTask] in
            guard readStateTask.canSync else { return }
            do {
                try await readStateTask.markAsUnread(messageIDs)
            } catch {
                FileLog.shared.addMessage("What's New: failed to mark messages unread: \(error.localizedDescription)")
            }
        }
    }

    /// Records that the Profile tab has pointed the user at the messages, so its dot stays off until
    /// a message arrives that it hasn't.
    public func markAsSeen(_ messageIDs: some Sequence<String>) {
        updateReadState { $0.seenMessageIDs.formUnion(messageIDs) }
    }

    /// Records that the feed has listed the messages, so the dot on the What's New button stays off
    /// until a message arrives that it hasn't. The Profile tab has nothing left to point at either.
    public func markAsListed(_ messageIDs: some Sequence<String>) {
        let messageIDs = Set(messageIDs)
        updateReadState {
            $0.listedMessageIDs.formUnion(messageIDs)
            $0.seenMessageIDs.formUnion(messageIDs)
        }
    }

    /// Records that the user answered a research poll, which keeps it closed from then on.
    public func markAsResponded(toPoll pollID: String) {
        updateReadState { $0.respondedPollIDs.insert(pollID) }
    }

    /// Forgets which messages were read, for when the account signs out: what one user read isn't
    /// the next user's, and leaving it here would push it onto whichever account signs in next.
    ///
    /// What the dots have pointed at stays, since it belongs to the device rather than the account,
    /// and the messages that come back unread don't light either dot up again.
    @discardableResult
    public func forgetReadMessages() -> Task<Void, Never> {
        Task { [weak self] in
            await self?.loadReadStateIfNeeded()
            self?.updateReadState { $0.readMessageIDs = [] }
        }
    }

    /// Forgets every message read, seen or listed and every poll answered, bringing back each
    /// indicator and reopening each poll.
    ///
    /// The messages in the catalog stay unseen rather than being caught up on again, so the dots come
    /// back for them. Local only: signed in, the next sync takes the account's read messages back on.
    public func resetReadState() {
        hasLoadedReadState = true
        readState = WhatsNewReadState(isCaughtUp: true)
        readStateStore.save(readState)
    }

    /// Forgets everything `resetReadState()` does and catches up on the catalog again, as on the
    /// first run, so the dots stay off for the messages already in it.
    public func resetToFirstRun() {
        hasLoadedReadState = true
        readState = WhatsNewReadState()
        readStateStore.save(readState)
        if let catalog {
            publish(catalog)
        }
    }

    /// Tells the account what this device has read and takes on what the user read elsewhere.
    ///
    /// Overlapping calls share one run, and anything read while that run is in flight starts another
    /// as soon as it finishes, so a message read mid-sync isn't left behind.
    @discardableResult
    public func syncReadState() -> Task<Void, Never> {
        if let syncTask {
            isSyncPending = true
            return syncTask
        }

        let syncTask = Task { [weak self] in
            while let self {
                self.isSyncPending = false
                await self.performReadStateSync()
                guard self.isSyncPending else { break }
            }
            self?.syncTask = nil
        }
        self.syncTask = syncTask
        return syncTask
    }

    #if DEBUG
    /// Whether the feed shows the mock catalog instead of the published one, for trying it out from
    /// the developer menu. Read state is kept on the device and never synced for the mock.
    public var usesMockCatalog: Bool {
        get { userDefaults.bool(forKey: Self.usesMockCatalogKey) }
        set {
            userDefaults.set(newValue, forKey: Self.usesMockCatalogKey)
            catalog = nil
            refresh()
        }
    }

    nonisolated private static let usesMockCatalogKey = "WhatsNewUsesMockCatalog"
    #endif

    private func performRefresh() async {
        await loadReadStateIfNeeded()

        #if DEBUG
        if usesMockCatalog {
            catalog = .mock
            return
        }
        #endif

        if catalog == nil, let cached = await cachedCatalog() {
            publish(cached)
        }

        let isStale = DateUtil.hasEnoughTimePassed(since: await cachedCatalogDate(), time: refreshInterval)
        if catalog == nil || isStale || isRefreshForced {
            do {
                publish(try await task.refresh())
            } catch {
                FileLog.shared.addMessage("What's New: failed to refresh the catalog: \(error.localizedDescription)")
            }
        }

        syncReadState()
    }

    /// Makes the catalog the one the app works from, catching up on its messages first if it's the
    /// first to reach this device, so the dots never count them even for a moment.
    private func publish(_ catalog: WhatsNewCatalog) {
        if !readState.isCaughtUp {
            let messageIDs = catalog.messages.map(\.id)
            updateReadState {
                $0.seenMessageIDs.formUnion(messageIDs)
                $0.listedMessageIDs.formUnion(messageIDs)
                $0.isCaughtUp = true
            }
        }
        self.catalog = catalog
    }

    /// Reconciles the read state with the account: what this device has read that the account
    /// hasn't, then what the account has read that this device hasn't.
    ///
    /// Only the messages in the catalog are reconciled, and only `read` is: nothing else the state
    /// holds — what the dots have pointed at, which polls were answered — means anything off this
    /// device.
    private func performReadStateSync() async {
        guard readStateTask.canSync else { return }
        #if DEBUG
        guard !usesMockCatalog else { return }
        #endif

        let messageIDs = Set(catalog?.messages.map(\.id) ?? [])
        guard !messageIDs.isEmpty else { return }
        let read = readState.readMessageIDs.intersection(messageIDs)

        do {
            let remotelyRead = try await readStateTask.readMessageIDs(among: messageIDs)

            let unsynced = read.subtracting(remotelyRead)
            if !unsynced.isEmpty {
                try await readStateTask.markAsRead(unsynced)
            }

            guard !remotelyRead.isEmpty else { return }
            updateReadState { $0.readMessageIDs.formUnion(remotelyRead) }
        } catch {
            FileLog.shared.addMessage("What's New: failed to sync the read state: \(error.localizedDescription)")
        }
    }

    /// Saves a change to the read state once the copy on disk has been read back, since saving
    /// before then would overwrite it. The load saves the two merged instead.
    ///
    /// Returns whether the change left the state any different.
    @discardableResult
    private func updateReadState(_ update: (inout WhatsNewReadState) -> Void) -> Bool {
        var readState = self.readState
        update(&readState)
        guard readState != self.readState else { return false }

        self.readState = readState
        if hasLoadedReadState {
            readStateStore.save(readState)
        }
        return true
    }

    /// Reads back the state saved in an earlier session, keeping anything marked since launch.
    ///
    /// A reset made while the file is being read wins over what was in it.
    private func loadReadStateIfNeeded() async {
        guard !hasLoadedReadState else { return }
        let stored = await storedReadState()
        guard !hasLoadedReadState else { return }
        hasLoadedReadState = true

        let merged = stored.merging(readState)
        if merged != readState {
            readState = merged
        }
        if merged != stored {
            readStateStore.save(merged)
        }
    }

    /// Reads the cached catalog off the main thread, so a refresh on becoming active doesn't decode
    /// it while the app is drawing its first frame.
    nonisolated private func cachedCatalog() async -> WhatsNewCatalog? {
        task.cachedCatalog()
    }

    nonisolated private func cachedCatalogDate() async -> Date? {
        task.cachedCatalogDate
    }

    nonisolated private func storedReadState() async -> WhatsNewReadState {
        readStateStore.load()
    }
}
