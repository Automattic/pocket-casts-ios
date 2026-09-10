import Foundation
import PocketCastsUtils

/// Keeps the What's New catalog in memory and up to date.
///
/// The catalog is one small file published for the whole platform, so the app works from the last
/// copy it fetched rather than from a request: the feed opens on the messages it already has
/// instead of a spinner, and anything deriving state from the feed — the unread dot on Profile —
/// can answer without waiting on the network.
///
/// Refreshing is driven by the app becoming active, which covers a cold launch and every return
/// from the background, and throttled by how old the copy on disk is. A timer would keep firing
/// against a file that changes a few times a month, and refreshing only at launch would leave a
/// user who never quits the app on whatever was published the day they installed it.
@MainActor
public final class WhatsNewManager: ObservableObject {
    nonisolated public static let shared = WhatsNewManager()

    /// The catalog the app is working from: the last copy fetched, read back from disk on the first
    /// refresh of the session.
    @Published public private(set) var catalog: WhatsNewCatalog?

    /// How long a fetched catalog is treated as current before the next foreground replaces it.
    nonisolated public static let refreshInterval: TimeInterval = 6.hours

    nonisolated private let task: WhatsNewCatalogTask
    private let refreshInterval: TimeInterval
    private var refreshTask: Task<Void, Never>?

    nonisolated public init(task: WhatsNewCatalogTask = WhatsNewCatalogTask(),
                            refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) {
        self.task = task
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
        }
        self.refreshTask = refreshTask
        return refreshTask
    }

    private func performRefresh() async {
        if catalog == nil, let cached = await cachedCatalog() {
            catalog = cached
        }

        guard catalog == nil || DateUtil.hasEnoughTimePassed(since: await cachedCatalogDate(), time: refreshInterval) else { return }

        do {
            catalog = try await task.refresh()
        } catch {
            FileLog.shared.addMessage("What's New: failed to refresh the catalog: \(error.localizedDescription)")
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
}
