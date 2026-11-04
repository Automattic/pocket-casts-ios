import Foundation
import PocketCastsServer
import PocketCastsUtils

/// Owns a `CustomRefreshControl` and wires it up to a "full sync" refresh:
/// triggers `RefreshManager.shared.refreshPodcasts()` on pull, and observes
/// the resulting server/sync notifications to update the status text and
/// dismiss the control when the sync finishes.
///
/// The owner is responsible for assigning `refreshControl` to a scroll view.
final class FullSyncRefreshController {
    let refreshControl = CustomRefreshControl()

    private let source: AnalyticsSource

    init(source: AnalyticsSource) {
        self.source = source

        refreshControl.perform = { [weak self] _ in
            self?.beginRefreshing()
        }

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(podcastsRefreshed), name: ServerNotifications.podcastsRefreshed, object: nil)
        center.addObserver(self, selector: #selector(podcastRefreshFailed), name: ServerNotifications.podcastRefreshFailed, object: nil)
        center.addObserver(self, selector: #selector(podcastsRefreshed), name: Constants.Notifications.opmlImportCompleted, object: nil)
        center.addObserver(self, selector: #selector(syncCompleted), name: ServerNotifications.syncCompleted, object: nil)
        center.addObserver(self, selector: #selector(refreshThrottled), name: ServerNotifications.podcastRefreshThrottled, object: nil)
        center.addObserver(self, selector: #selector(syncFailed), name: ServerNotifications.syncFailed, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Whether the sync runs alongside the refresh and finishes first, so the refresh is the last step.
    private var syncsBeforeRefresh: Bool {
        FeatureFlag.syncBeforeRefresh.enabled && SyncManager.isUserLoggedIn()
    }

    private var didSyncFail = false

    private func beginRefreshing() {
        didSyncFail = false
        refreshControl.set(text: L10n.refreshControlFetchingEpisodes)
        RefreshManager.shared.refreshPodcasts()
        Analytics.track(.pulledToRefresh, properties: ["source": source])
    }

    @objc private func podcastsRefreshed() {
        if syncsBeforeRefresh {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.finishRefreshing(message: self.didSyncFail ? L10n.refreshControlSyncFailed : L10n.refreshControlRefreshComplete)
            }
            return
        }
        if SyncManager.isUserLoggedIn() {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.refreshControl.isRefreshing else { return }
                self.refreshControl.set(text: L10n.refreshControlSyncingPodcasts)
            }
            return
        }
        finishRefreshing(message: L10n.refreshControlRefreshComplete)
    }

    @objc private func podcastRefreshFailed() {
        finishRefreshing(message: L10n.refreshControlRefreshFailed)
    }

    @objc private func refreshThrottled() {
        finishRefreshing(message: L10n.refreshControlRefreshComplete)
    }

    @objc private func syncCompleted() {
        guard !syncsBeforeRefresh else { return }
        finishRefreshing(message: L10n.refreshControlRefreshComplete)
    }

    @objc private func syncFailed() {
        guard !syncsBeforeRefresh else {
            DispatchQueue.main.async { [weak self] in
                self?.didSyncFail = true
            }
            return
        }
        finishRefreshing(message: L10n.refreshControlSyncFailed)
    }

    private func finishRefreshing(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.refreshControl.isRefreshing else { return }
            self.refreshControl.set(text: message)
            self.refreshControl.endRefreshing()
        }
    }
}
