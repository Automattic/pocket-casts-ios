import PocketCastsServer
import PocketCastsUtils
import UIKit

extension PlaylistDetailViewController {
    struct PlaylistReloadScope: OptionSet {
        let rawValue: Int

        static let episodes = PlaylistReloadScope(rawValue: 1 << 0)
        static let playlist = PlaylistReloadScope(rawValue: 1 << 1)
    }

    func addObservers() {
        addCustomObserver(ServerNotifications.podcastsRefreshed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.opmlImportCompleted, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackTrackChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackEnded, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playbackFailed, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.playlistChanged, selector: #selector(refreshFilterFromNotification))
        addCustomObserver(Constants.Notifications.episodePlayStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeArchiveStatusChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeStarredChanged, selector: #selector(refreshEpisodesFromNotification))
        addCustomObserver(Constants.Notifications.episodeDownloaded, selector: #selector(refreshEpisodesIfFilteringByDownloadStatus))
        addCustomObserver(Constants.Notifications.episodeDownloadStatusChanged, selector: #selector(refreshEpisodesIfFilteringByDownloadStatus))
        addCustomObserver(Constants.Notifications.manyEpisodesChanged, selector: #selector(refreshEpisodesFromNotification))
    }

    @objc func refreshEpisodesIfFilteringByDownloadStatus(notification: Notification) {
        guard viewModel.playlist.isAffected(by: .downloadStatus) else { return }

        reloader.request(.episodes)
    }
}
