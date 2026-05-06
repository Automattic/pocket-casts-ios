import Foundation
import PocketCastsServer

/// Owns a `CustomRefreshControl` and wires it up to a user-files refresh:
/// triggers `UserEpisodeManager.updateUserEpisodes()` on pull, and observes
/// the resulting server notifications to update the status text and dismiss
/// the control when the refresh finishes.
///
/// The owner is responsible for assigning `refreshControl` to a scroll view
/// and customising its appearance.
final class UploadedFilesRefreshController {
    let refreshControl = CustomRefreshControl()

    private let source: AnalyticsSource

    init(source: AnalyticsSource) {
        self.source = source

        refreshControl.perform = { [weak self] _ in
            self?.beginRefreshing()
        }

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(userEpisodesRefreshed), name: ServerNotifications.userEpisodesRefreshed, object: nil)
        center.addObserver(self, selector: #selector(userEpisodesRefreshFailed), name: ServerNotifications.userEpisodesRefreshFailed, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func beginRefreshing() {
        refreshControl.set(text: L10n.refreshControlRefreshingFiles)
        UserEpisodeManager.updateUserEpisodes()
        Analytics.track(.pulledToRefresh, properties: ["source": source])
    }

    @objc private func userEpisodesRefreshed() {
        finishRefreshing(message: L10n.refreshControlRefreshComplete)
    }

    @objc private func userEpisodesRefreshFailed() {
        finishRefreshing(message: L10n.refreshControlRefreshFailed)
    }

    private func finishRefreshing(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.refreshControl.isRefreshing else { return }
            self.refreshControl.set(text: message)
            self.refreshControl.endRefreshing()
        }
    }
}
