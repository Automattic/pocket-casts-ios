import PocketCastsServer
import UIKit

class UploadedRefreshControl: PCRefreshControl {
    override func parentViewControllerDidAppear() {
        parentViewVisible = true

        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(userEpisodesRefreshed), name: ServerNotifications.userEpisodesRefreshed, object: nil)
        notifCenter.addObserver(self, selector: #selector(userEpisodestRefreshFailed), name: ServerNotifications.userEpisodesRefreshFailed, object: nil)
    }

    override func parentViewControllerDidDisappear() {
        parentViewVisible = false

        let notifCenter = NotificationCenter.default
        notifCenter.removeObserver(self, name: ServerNotifications.userEpisodesRefreshed, object: nil)
        notifCenter.removeObserver(self, name: ServerNotifications.userEpisodesRefreshFailed, object: nil)

        if refreshing {
            endRefreshing(false)
        }
    }

    override func beginRefreshing() {
        refreshing = true

        UIView.animate(withDuration: 0.2, animations: {
            self.offsetToPullDown()
        })

        refreshLabel.text = L10n.refreshControlRefreshingFiles
        startRefreshAnimation()

        UserEpisodeManager.updateUserEpisodes()
    }

    // MARK: - Refreshing Events

    @objc private func userEpisodesRefreshed() {
        processRefreshCompleted(L10n.refreshControlRefreshComplete)
    }

    @objc private func userEpisodestRefreshFailed() {
        processRefreshCompleted(L10n.refreshControlRefreshFailed)
    }
}
