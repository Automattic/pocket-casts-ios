import Foundation
import PocketCastsDataModel
import PocketCastsServer

extension WatchSyncManager: ServerSyncDelegate {
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

    func applyAutoArchivingToAllPodcasts() {}

    func subscribedToPodcast() {}

    // MARK: - Filters

    func filterChanged() {
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)
    }

    // MARK: - Episode functions

    func episodeStarredChanged(episode: Episode) {
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
        checkForUpNextAutoDownloads()
    }

    func cleanupCloudOnlyFiles() {}

    func autoDownloadUserEpisodes(episodes: [UserEpisode]) {}

    func userEpisodeFileProtocol() -> FilePathProtocol {
        DownloadManager.shared
    }

    func deselectedChaptersChanged() {
        PlaybackManager.shared.forceUpdateChapterInfo()
    }

    // MARK: - Settings

    func isPushEnabled() -> Bool {
        false
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

    func autoDownloadLatestEpisode(episode: Episode) {}

    func minTimeBetweenProgressSaves() -> Double {
        2.minutes
    }

    func production() -> Bool {
        #if STAGING
            return false
        #else
            return true
        #endif
    }
}
