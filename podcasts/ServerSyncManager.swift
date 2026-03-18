import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class ServerSyncManager: ServerSyncDelegate {
    static let shared = ServerSyncManager()
    private static let networkDataUsageRetentionPeriod: TimeInterval = 60.days
    private static let networkDataUsageCleanupInterval: TimeInterval = 24.hours

    // MARK: - Podcast functions

    func podcastUpdated(podcastUuid: String) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcastUuid)
    }

    func podcastAdded(podcastUuid: String) {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastAdded, object: podcastUuid)
    }

    func checkForUnusedPodcasts() {
        Task {
            await PodcastManager.shared.checkForUnusedPodcasts()
        }
    }

    func applyAutoArchivingToAllPodcasts() {
        PodcastManager.shared.applyAutoArchivingToAllPodcasts()
    }

    func subscribedToPodcast() {
        AnalyticsHelper.subscribedToPodcast()
    }

    // MARK: - Playlists

    func playlistChanged() {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
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

    func deselectedChaptersChanged() {
        PlaybackManager.shared.forceUpdateChapterInfo()
    }

    func cleanupAllUnusedEpisodeBuffers() {
        EpisodeManager.cleanupAllUnusedEpisodeBuffers()
    }

    func episodeCanBeCleanedUp(episode: Episode) -> Bool {
        episode.episodeCanBeCleanedUp()
    }

    // User Episodes functions
    func deleteFromDevice(userEpisode: UserEpisode) {
        #if !APPCLIP
        UserEpisodeManager.deleteFromDevice(userEpisode: userEpisode)
        #endif
    }

    func performActionsAfterSync() {
        cleanupNetworkDataUsageIfNeeded()
        PodcastManager.shared.checkForExpiredPodcastsAndCleanup()
        PodcastManager.shared.checkForPendingAndAutoDownloads()
        #if !APPCLIP
        PlaylistManager.checkForAutoDownloads()
        UserEpisodeManager.checkForPendingUploads()
        UserEpisodeManager.checkForPendingCloudDeletes()
        #endif
        DispatchQueue.main.async {
            Analytics.shared.refreshRegistered()
            PlaybackManager.shared.effectsChangedExternally()
            Theme.sharedTheme.toggleTheme()
            #if !APPCLIP
            NotificationsHelper.shared.register(checkToken: true)
            #endif
        }
    }

    private func cleanupNetworkDataUsageIfNeeded() {
        guard FeatureFlag.trackNetworkDataUsage.enabled else { return }

        let defaults = UserDefaults.standard
        let lastCleanupDate = defaults.object(forKey: Constants.UserDefaults.lastNetworkDataUsageCleanupDate) as? Date

        guard DateUtil.hasEnoughTimePassed(since: lastCleanupDate, time: Self.networkDataUsageCleanupInterval) else {
            return
        }

        let cleanupDate = Date()
        defaults.set(cleanupDate, forKey: Constants.UserDefaults.lastNetworkDataUsageCleanupDate)

        Task {
            let didCleanup = await DataManager.sharedManager.networkDataUsageManager.deleteRecords(
                olderThan: Date(timeIntervalSinceNow: -Self.networkDataUsageRetentionPeriod)
            )

            if !didCleanup {
                defaults.set(lastCleanupDate, forKey: Constants.UserDefaults.lastNetworkDataUsageCleanupDate)
            }
        }
    }

    func cleanupCloudOnlyFiles() {
        #if !APPCLIP
        UserEpisodeManager.cleanupCloudOnlyFiles()
        #endif
    }

    func autoDownloadUserEpisodes(episodes: [UserEpisode]) {
        let autoDownloadsRequireWifi = ServerSettings.userEpisodeOnlyOnWifi()
        let isWiFiConnected = NetworkUtils.shared.isConnectedToUnexpensiveConnection()

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
        #if APPCLIP
        false
        #else
        NotificationsHelper.shared.pushEnabled()
        #endif
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

    func autoDownloadLatestEpisodes(uuids: [String]) {
        if Settings.autoDownloadEnabled() {
            if Settings.autoDownloadMobileDataAllowed() || NetworkUtils.shared.isConnectedToUnexpensiveConnection() {
                for uuid in uuids {
                    AnalyticsEpisodeHelper.shared.downloaded(episodeUUID: uuid)
                    DownloadManager.shared.addToQueue(episodeUuid: uuid)
                }
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
