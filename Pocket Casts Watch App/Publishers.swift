import Combine
import Foundation
import PocketCastsServer

extension Publishers {
    enum Notification {
        // Playback
        static let playbackStarted = NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted)
        static let playbackEnded = NotificationCenter.default.publisher(for: Constants.Notifications.playbackEnded)
        static let playbackPaused = NotificationCenter.default.publisher(for: Constants.Notifications.playbackPaused)

        static let playbackProgress = NotificationCenter.default.publisher(for: Constants.Notifications.playbackProgress)
        static let episodeDurationChanged = NotificationCenter.default.publisher(for: Constants.Notifications.episodeDurationChanged)
        static let progressUpdated = Publishers.Merge(playbackProgress, episodeDurationChanged)

        static let playbackTrackChanged = NotificationCenter.default.publisher(for: Constants.Notifications.playbackTrackChanged)
        static let playbackChanged = Publishers.Merge4(playbackStarted, playbackEnded, playbackPaused, playbackTrackChanged)
        static let podcastChapterChanged = NotificationCenter.default.publisher(for: Constants.Notifications.podcastChapterChanged)
        static let podcastChaptersDidUpdate = NotificationCenter.default.publisher(for: Constants.Notifications.podcastChaptersDidUpdate)
        static let playbackEffectsChanged = NotificationCenter.default.publisher(for: Constants.Notifications.playbackEffectsChanged)

        // Episode Status Changes
        static let episodeArchiveStatusChanged = NotificationCenter.default.publisher(for: Constants.Notifications.episodeArchiveStatusChanged, object: nil)
        static let episodePlayStatusChanged = NotificationCenter.default.publisher(for: Constants.Notifications.episodePlayStatusChanged, object: nil)
        static let episodeStarredChanged = NotificationCenter.default.publisher(for: Constants.Notifications.episodeStarredChanged, object: nil)
        static let userEpisodeDeleted = NotificationCenter.default.publisher(for: Constants.Notifications.userEpisodeDeleted, object: nil)
        static let userEpisodesRefreshed = NotificationCenter.default.publisher(for: ServerNotifications.userEpisodesRefreshed, object: nil)

        // Episode Download
        static let downloadProgress = NotificationCenter.default.publisher(for: Constants.Notifications.downloadProgress)
        static let episodeDownloadStatusChanged = NotificationCenter.default.publisher(for: Constants.Notifications.episodeDownloadStatusChanged)
        static let episodeDownloaded = NotificationCenter.default.publisher(for: Constants.Notifications.episodeDownloaded)
        static let downloadStatusChanged = Publishers.Merge(episodeDownloadStatusChanged, episodeDownloaded)

        // Queue Changes
        static let upNextEpisodeAdded = NotificationCenter.default.publisher(for: Constants.Notifications.upNextEpisodeAdded)
        static let upNextEpisodeRemoved = NotificationCenter.default.publisher(for: Constants.Notifications.upNextEpisodeRemoved)
        static let upNextEpisodeChanged = Publishers.Merge(upNextEpisodeAdded, upNextEpisodeRemoved)
        static let upNextQueueChanged = NotificationCenter.default.publisher(for: Constants.Notifications.upNextQueueChanged)

        // Data Updates
        static let dataUpdated = NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: WatchConstants.Notifications.dataUpdated), object: nil)
        static let podcastUpdated = NotificationCenter.default.publisher(for: Constants.Notifications.podcastUpdated)
        static let folderChanged = NotificationCenter.default.publisher(for: Constants.Notifications.folderChanged)
    }
}
