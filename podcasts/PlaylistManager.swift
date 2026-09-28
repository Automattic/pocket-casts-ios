import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class PlaylistManager {
    enum DefaultUUIDs {
        static let newReleases = "2797DCF8-1C93-4999-B52A-D1849736FA2C"
        static let inProgress = "D89A925C-5CE1-41A4-A879-2751838CE5CE"
    }

    // MARK: - Default Playlists

    class func createDefaultPlaylists() {
        // new releases
        var existingUuid = DefaultUUIDs.newReleases
        var existingFilter = DataManager.shared.findPlaylist(uuid: existingUuid)
        if existingFilter == nil {
            let newReleases = EpisodeFilter()
            newReleases.filterUnplayed = true
            newReleases.filterPartiallyPlayed = true
            newReleases.filterAudioVideoType = AudioVideoFilter.all.rawValue
            newReleases.filterAllPodcasts = true
            newReleases.sortPosition = 0
            newReleases.playlistName = L10n.filtersDefaultNewReleases
            newReleases.filterDownloaded = true
            newReleases.filterNotDownloaded = true
            newReleases.filterHours = (24 * 14) // two weeks
            newReleases.uuid = existingUuid
            newReleases.customIcon = PlaylistIcon.redRecent.rawValue
            newReleases.syncStatus = SyncStatus.synced.rawValue
            DataManager.shared.save(playlist: newReleases)
        }

        // don't create the rest of these if the user already has playlists
        let playlistsCount = DataManager.shared.playlistsCount(includeDeleted: false)
        if playlistsCount > 1 {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

            return
        }

        // in progress
        existingUuid = DefaultUUIDs.inProgress
        existingFilter = DataManager.shared.findPlaylist(uuid: existingUuid)
        if existingFilter == nil {
            let inProgress = EpisodeFilter()
            inProgress.filterAllPodcasts = true
            inProgress.filterAudioVideoType = AudioVideoFilter.all.rawValue
            inProgress.sortPosition = 2
            inProgress.playlistName = L10n.inProgress
            inProgress.filterDownloaded = true
            inProgress.filterNotDownloaded = true
            inProgress.filterUnplayed = false
            inProgress.filterPartiallyPlayed = true
            inProgress.filterFinished = false
            inProgress.filterHours = (24 * 31) // one month
            inProgress.uuid = existingUuid
            inProgress.customIcon = PlaylistIcon.purpleUnplayed.rawValue
            inProgress.syncStatus = SyncStatus.synced.rawValue
            DataManager.shared.save(playlist: inProgress)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
    }

    class func delete(playlist: EpisodeFilter?, fireEvent: Bool) {
        guard let playlist else { return }

        if SyncManager.isUserLoggedIn() {
            playlist.wasDeleted = true
            playlist.syncStatus = SyncStatus.notSynced.rawValue
            DataManager.shared.save(playlist: playlist)
        } else {
            DataManager.shared.delete(playlist: playlist)
        }

        if fireEvent {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
        }
    }

    class func createNewPlaylist() -> EpisodeFilter {
        let playlist = EpisodeFilter.makeDefault()
        playlist.playlistName = L10n.filtersDefaultNewFilter
        playlist.sortPosition = nextSortPosition()
        playlist.isNew = true
        return playlist
    }

    class func checkForAutoDownloads() {
        for playlist in DataManager.shared.allPlaylists(includeDeleted: false) {
            queueAutoDownloads(for: playlist)
        }
    }

    /// Call when episodes are added to a playlist or auto download is turned on for it outside of a sync.
    class func checkForAutoDownloads(in playlist: EpisodeFilter) {
        guard playlist.autoDownloadEpisodes else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if queueAutoDownloads(for: playlist) {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)
            }
        }
    }

    @discardableResult
    private class func queueAutoDownloads(for playlist: EpisodeFilter) -> Bool {
        guard playlist.autoDownloadEpisodes else { return false }

        let query = PlaylistQueryBuilder.query(clause: .episode, for: playlist, episodeUuidToAdd: playlist.episodeUuidToAddToQueries(), limit: Int(playlist.maxAutoDownloadEpisodes()))
        let episodes = DataManager.shared.findPlaylistEpisodesWhere(query: query, arguments: nil)

        let onWifi = NetworkUtils.shared.isConnectedToUnexpensiveConnection()
        let mobileDataAllowed = Settings.autoDownloadMobileDataAllowed()
        var didQueue = false
        for episode in episodes {
            if episode.downloaded(pathFinder: DownloadManager.shared) || episode.queued() { continue }

            if !onWifi, !mobileDataAllowed {
                DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            } else {
                DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            }
            didQueue = true
        }
        return didQueue
    }

    class func handlePodcastUnsubscribed(podcastUuid: String) {
        let playlists = DataManager.shared.allPlaylists(includeDeleted: false)
        if playlists.isEmpty { return }

        for playlist in playlists {
            guard !playlist.filterAllPodcasts, !playlist.podcastUuids.isEmpty else { continue }

            var podcastUuids = playlist.podcastUuids.components(separatedBy: ",")
            guard let indexOfUuid = podcastUuids.firstIndex(of: podcastUuid) else { continue }

            podcastUuids.remove(at: indexOfUuid)
            playlist.podcastUuids = podcastUuids.joined(separator: ",")
            if SyncManager.isUserLoggedIn() { playlist.syncStatus = SyncStatus.notSynced.rawValue }
            DataManager.shared.save(playlist: playlist)
        }
    }

    class func autoDownloadPlaylistsCount() -> Int {
        let playlists = DataManager.shared.allPlaylists(includeDeleted: false)

        return playlists.filter { playlist -> Bool in
            playlist.autoDownloadEpisodes
        }.count
    }

    private class func nextSortPosition() -> Int32 {
        Int32(DataManager.shared.nextSortPositionForPlaylist())
    }
}
