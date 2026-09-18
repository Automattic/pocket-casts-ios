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
    private let refreshInterval: TimeInterval
    private var refreshTask: Task<Void, Never>?
    private var isRefreshForced = false
    private var hasLoadedReadState = false
    private var syncTask: Task<Void, Never>?
    private var isSyncPending = false

    /// Messages a reset has to mark unread on the account, kept until the request goes through so a
    /// reset made offline isn't lost.
    private var pendingUnreadMessageIDs: Set<String> = []

    /// Counts resets, so a sync that was already asking the server when the state was reset doesn't
    /// put back what the reset just cleared.
    private var resetCount = 0

    nonisolated public init(task: WhatsNewCatalogTask = WhatsNewCatalogTask(),
                            readStateStore: WhatsNewReadStateStore = WhatsNewReadStateStore(),
                            readStateTask: WhatsNewReadStateTask = WhatsNewReadStateTask(),
                            refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) {
        self.task = task
        self.readStateStore = readStateStore
        self.readStateTask = readStateTask
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

    /// Records that the Profile tab has pointed the user at the messages, so its dot stays off until
    /// a message arrives that it hasn't.
    public func markAsSeen(_ messageIDs: some Sequence<String>) {
        updateReadState { $0.seenMessageIDs.formUnion(messageIDs) }
    }

    /// Records that the feed has listed the messages, so the dot on the What's New row stays off
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

    /// Forgets every message read, seen or listed and every poll answered, bringing back each
    /// indicator and reopening each poll.
    ///
    /// The account is told to forget it too, or the next sync would read it all straight back.
    public func resetReadState() {
        hasLoadedReadState = true
        resetCount += 1
        pendingUnreadMessageIDs.formUnion(readState.readMessageIDs)
        readState = WhatsNewReadState()
        readStateStore.save(readState)
        syncReadState()
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

    private func performRefresh() async {
        await loadReadStateIfNeeded()

        if catalog == nil, let cached = await cachedCatalog() {
            catalog = cached
        }

        let isStale = DateUtil.hasEnoughTimePassed(since: await cachedCatalogDate(), time: refreshInterval)
        if catalog == nil || isStale || isRefreshForced {
            do {
                catalog = try await task.refresh()
            } catch {
                FileLog.shared.addMessage("What's New: failed to refresh the catalog: \(error.localizedDescription)")
            }
        }

        await syncReadState().value
    }

    /// Reconciles the read state with the account: what a reset cleared, then what this device has
    /// read that the account hasn't, then what the account has read that this device hasn't.
    ///
    /// Only the messages in the catalog are reconciled, and only `read` is: nothing else the state
    /// holds — what the dots have pointed at, which polls were answered — means anything off this
    /// device.
    private func performReadStateSync() async {
        guard readStateTask.canSync else { return }

        let resetCount = self.resetCount
        let unread = pendingUnreadMessageIDs
        pendingUnreadMessageIDs = []

        let messageIDs = Set(catalog?.messages.map(\.id) ?? [])
        let read = readState.readMessageIDs.intersection(messageIDs)

        do {
            if !unread.isEmpty {
                try await readStateTask.markAsUnread(unread)
            }
            guard !messageIDs.isEmpty else { return }

            let remotelyRead = try await readStateTask.readMessageIDs(among: messageIDs)

            let unsynced = read.subtracting(remotelyRead)
            if !unsynced.isEmpty {
                try await readStateTask.markAsRead(unsynced)
            }

            guard resetCount == self.resetCount, !remotelyRead.isEmpty else { return }
            updateReadState { $0.readMessageIDs.formUnion(remotelyRead) }
        } catch {
            pendingUnreadMessageIDs.formUnion(unread)
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
