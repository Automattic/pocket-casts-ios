import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class ServerSyncManager: ServerSyncDelegate {
    static let shared = ServerSyncManager()

    // MARK: - Podcast functions

    func podcastUpdated(podcastUuid: String) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcastUuid)
    }

    func podcastAdded(podcastUuid: String) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastAdded, object: podcastUuid)
    }

    func checkForUnusedPodcasts() {
        PodcastManager.shared.checkForUnusedPodcasts()
    }

    func applyAutoArchivingToAllPodcasts() {
        PodcastManager.shared.applyAutoArchivingToAllPodcasts()
    }

    func subscribedToPodcast() {
        AnalyticsHelper.subscribedToPodcast()
    }

    // MARK: - Filters

    func filterChanged() {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)
    }

    // MARK: - Episode functions

    func episodeStarredChanged(episode: Episode) {
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            PlaybackManager.shared.nowPlayingStarredChanged()
        }
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeStarredChanged, object: episode.uuid)
    }

    func archiveEpisodeExternal(episode: Episode) {
        EpisodeManager.archiveEpisodeExternal(episode)
    }

    func markEpisodeAsPlayedExternal(episode: Episode) {
        EpisodeManager.markEpisodeAsPlayedExternal(episode)
    }

    func cleanupAllUnusedEpisodeBuffers() {
        EpisodeManager.cleanupAllUnusedEpisodeBuffers()
    }

    func episodeCanBeCleanedUp(episode: Episode) -> Bool {
        episode.episodeCanBeCleanedUp()
    }

    // User Episodes functions
    func deleteFromDevice(userEpisode: UserEpisode) {
        UserEpisodeManager.deleteFromDevice(userEpisode: userEpisode)
    }

    func performActionsAfterSync() {
        PodcastManager.shared.checkForExpiredPodcastsAndCleanup()
        FilterManager.checkForAutoDownloads()
        PodcastManager.shared.checkForPendingAndAutoDownloads()
        UserEpisodeManager.checkForPendingUploads()
        UserEpisodeManager.checkForPendingCloudDeletes()
        DispatchQueue.main.async {
            PlaybackManager.shared.effectsChangedExternally()
        }
    }

    func cleanupCloudOnlyFiles() {
        UserEpisodeManager.cleanupCloudOnlyFiles()
    }

    func autoDownloadUserEpisodes(episodes: [UserEpisode]) {
        let autoDownloadsRequireWifi = ServerSettings.userEpisodeOnlyOnWifi()
        let isWiFiConnected = NetworkUtils.shared.isConnectedToWifi()

        for episode in episodes {
            if isWiFiConnected || !autoDownloadsRequireWifi {
                DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            } else {
                DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            }
        }
    }

    func userEpisodeFileProtocol() -> FilePathProtocol {
        DownloadManager.shared
    }

    // MARK: - Settings

    func isPushEnabled() -> Bool {
        NotificationsHelper.shared.pushEnabled()
    }

    func defaultPodcastGrouping() -> Int32 {
        Settings.defaultPodcastGrouping().rawValue
    }

    func defaultShowArchived() -> Bool {
        Settings.showArchivedDefault()
    }

    func uniqueAppId() -> String {
        UserDefaults.standard.string(forKey: Constants.UserDefaults.appId) ?? ""
    }

    func appVersion() -> String {
        Settings.appVersion()
    }

    func privateUserAgent() -> String {
        "Pocket Casts/iOS/" + Settings.appVersion()
    }

    func autoDownloadLatestEpisode(episode: Episode) {
        if Settings.autoDownloadEnabled() {
            if Settings.autoDownloadMobileDataAllowed() || NetworkUtils.shared.isConnectedToWifi() {
                DownloadManager.shared.addToQueue(episodeUuid: episode.uuid)
            }
        }
    }

    func minTimeBetweenProgressSaves() -> Double {
        Settings.minTimeBetweenProgressSaves()
    }

    func production() -> Bool {
        #if STAGING
            return false
        #else
            return true
        #endif
    }
}
