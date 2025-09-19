import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

class PlaylistManager {
    // MARK: - Default Playlists

    class func createDefaultPlaylists() {
        // new releases
        var existingUuid = "2797DCF8-1C93-4999-B52A-D1849736FA2C"
        var existingFilter = DataManager.sharedManager.findPlaylist(uuid: existingUuid)
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
            DataManager.sharedManager.save(playlist: newReleases)
        }

        // don't create the rest of these if the user already has playlists
        let playlistsCount = DataManager.sharedManager.playlistsCount(includeDeleted: false)
        if playlistsCount > 1 {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

            return
        }

        // in progress
        existingUuid = "D89A925C-5CE1-41A4-A879-2751838CE5CE"
        existingFilter = DataManager.sharedManager.findPlaylist(uuid: existingUuid)
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
            DataManager.sharedManager.save(playlist: inProgress)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
    }

    class func delete(playlist: EpisodeFilter?, fireEvent: Bool) {
        guard let playlist = playlist else { return }

        if SyncManager.isUserLoggedIn() {
            playlist.wasDeleted = true
            playlist.syncStatus = SyncStatus.notSynced.rawValue
            DataManager.sharedManager.save(playlist: playlist)
        } else {
            DataManager.sharedManager.delete(playlist: playlist)
        }

        if fireEvent {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
        }
    }

    class func createNewPlaylist() -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.uuid = UUID().uuidString
        playlist.playlistName = L10n.filtersDefaultNewFilter
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        playlist.sortPosition = nextSortPosition()
        playlist.filterPartiallyPlayed = true
        playlist.filterUnplayed = true
        playlist.filterFinished = true
        playlist.filterAudioVideoType = AudioVideoFilter.all.rawValue
        playlist.filterAllPodcasts = true
        playlist.filterDownloaded = true
        playlist.filterNotDownloaded = true
        playlist.customIcon = 0
        playlist.isNew = true
        return playlist
    }

    class func checkForAutoDownloads() {
        let playlists = DataManager.sharedManager.allPlaylists(includeDeleted: false)

        if playlists.isEmpty { return }

        let onWifi = NetworkUtils.shared.isConnectedToUnexpensiveConnection()
        let mobileDataAllowed = Settings.autoDownloadMobileDataAllowed()
        for playlist in playlists {
            guard playlist.autoDownloadEpisodes else { continue }

            let query: String
            if FeatureFlag.playlistsRebranding.enabled {
                query = PlaylistQueryBuilder.query(clause: .episode, for: playlist, episodeUuidToAdd: playlist.episodeUuidToAddToQueries(), limit: Int(playlist.maxAutoDownloadEpisodes()))
            } else {
                query = PlaylistQueryBuilder.queryFor(filter: playlist, episodeUuidToAdd: playlist.episodeUuidToAddToQueries(), limit: Int(playlist.maxAutoDownloadEpisodes()))
            }

            let episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
            for episode in episodes {
                if episode.downloaded(pathFinder: DownloadManager.shared) || episode.queued() { continue }

                if !onWifi, !mobileDataAllowed {
                    DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
                } else {
                    DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
                }
            }
        }
    }

    class func handlePodcastUnsubscribed(podcastUuid: String) {
        let playlists = DataManager.sharedManager.allPlaylists(includeDeleted: false)
        if playlists.isEmpty { return }

        for playlist in playlists {
            guard !playlist.filterAllPodcasts, playlist.podcastUuids.count > 0 else { continue }

            var podcastUuids = playlist.podcastUuids.components(separatedBy: ",")
            guard let indexOfUuid = podcastUuids.firstIndex(of: podcastUuid) else { continue }

            podcastUuids.remove(at: indexOfUuid)
            playlist.podcastUuids = podcastUuids.joined(separator: ",")
            if SyncManager.isUserLoggedIn() { playlist.syncStatus = SyncStatus.notSynced.rawValue }
            DataManager.sharedManager.save(playlist: playlist)
        }
    }

    class func autoDownloadPlaylistsCount() -> Int {
        let playlists = DataManager.sharedManager.allPlaylists(includeDeleted: false)

        return playlists.filter { playlist -> Bool in
            playlist.autoDownloadEpisodes
        }.count
    }

    private class func nextSortPosition() -> Int32 {
        Int32(DataManager.sharedManager.nextSortPositionForPlaylist())
    }
}
