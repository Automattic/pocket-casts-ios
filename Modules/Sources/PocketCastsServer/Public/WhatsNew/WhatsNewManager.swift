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
/// Read state is kept in a file until it syncs with the server, and is read back before the first
/// catalog is published, so a message read in an earlier session never shows up unread, even for a
/// moment.
@MainActor
public final class WhatsNewManager: ObservableObject {
    nonisolated public static let shared = WhatsNewManager()

    /// The catalog the app is working from: the last copy fetched, read back from disk on the first
    /// refresh of the session.
    @Published public private(set) var catalog: WhatsNewCatalog?

    /// Which messages the user has read, and which the feed and the Profile tab have already pointed
    /// them at.
    @Published public private(set) var readState = WhatsNewReadState()

    /// How long a fetched catalog is treated as current before the next foreground replaces it.
    nonisolated public static let refreshInterval: TimeInterval = 6.hours

    nonisolated private let task: WhatsNewCatalogTask
    nonisolated private let readStateStore: WhatsNewReadStateStore
    private let refreshInterval: TimeInterval
    private var refreshTask: Task<Void, Never>?
    private var isRefreshForced = false
    private var hasLoadedReadState = false

    nonisolated public init(task: WhatsNewCatalogTask = WhatsNewCatalogTask(),
                            readStateStore: WhatsNewReadStateStore = WhatsNewReadStateStore(),
                            refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) {
        self.task = task
        self.readStateStore = readStateStore
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
        updateReadState { $0.readMessageIDs.formUnion(messageIDs) }
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

    /// Forgets every message read, seen or listed, bringing back each indicator.
    public func resetReadState() {
        hasLoadedReadState = true
        readState = WhatsNewReadState()
        readStateStore.save(readState)
    }

    private func performRefresh() async {
        await loadReadStateIfNeeded()

        if catalog == nil, let cached = await cachedCatalog() {
            catalog = cached
        }

        let isStale = DateUtil.hasEnoughTimePassed(since: await cachedCatalogDate(), time: refreshInterval)
        guard catalog == nil || isStale || isRefreshForced else { return }

        do {
            catalog = try await task.refresh()
        } catch {
            FileLog.shared.addMessage("What's New: failed to refresh the catalog: \(error.localizedDescription)")
        }
    }

    /// Saves a change to the read state once the copy on disk has been read back, since saving
    /// before then would overwrite it. The load saves the two merged instead.
    private func updateReadState(_ update: (inout WhatsNewReadState) -> Void) {
        var readState = self.readState
        update(&readState)
        guard readState != self.readState else { return }

        self.readState = readState
        if hasLoadedReadState {
            readStateStore.save(readState)
        }
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
