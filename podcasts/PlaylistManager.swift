import PocketCastsDataModel
import PocketCastsServer
import UIKit

class PlaylistManager {
    // MARK: - Default Filters

    class func createDefaultFilters() {
        // new releases
        var existingUuid = "2797DCF8-1C93-4999-B52A-D1849736FA2C"
        var existingFilter = DataManager.sharedManager.findFilter(uuid: existingUuid)
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
            DataManager.sharedManager.save(filter: newReleases)
        }

        // don't create the rest of these if the user already has playlists
        let filterCount = DataManager.sharedManager.filterCount(includeDeleted: false)
        if filterCount > 1 {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)

            return
        }

        // in progress
        existingUuid = "D89A925C-5CE1-41A4-A879-2751838CE5CE"
        existingFilter = DataManager.sharedManager.findFilter(uuid: existingUuid)
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
            DataManager.sharedManager.save(filter: inProgress)
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)
    }

    class func delete(filter: EpisodeFilter?, fireEvent: Bool) {
        guard let filter = filter else { return }

        if SyncManager.isUserLoggedIn() {
            filter.wasDeleted = true
            filter.syncStatus = SyncStatus.notSynced.rawValue
            DataManager.sharedManager.save(filter: filter)
        } else {
            DataManager.sharedManager.delete(filter: filter)
        }

        if fireEvent {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)
        }
    }

    class func createNewFilter() -> EpisodeFilter {
        let filter = EpisodeFilter()
        filter.uuid = UUID().uuidString
        filter.playlistName = L10n.filtersDefaultNewFilter
        filter.syncStatus = SyncStatus.notSynced.rawValue
        filter.sortPosition = nextSortPosition()
        filter.filterPartiallyPlayed = true
        filter.filterUnplayed = true
        filter.filterFinished = true
        filter.filterAudioVideoType = AudioVideoFilter.all.rawValue
        filter.filterAllPodcasts = true
        filter.filterDownloaded = true
        filter.filterNotDownloaded = true
        filter.customIcon = 0
        filter.isNew = true
        return filter
    }

    private class func nextSortPosition() -> Int32 {
        Int32(DataManager.sharedManager.nextSortPositionForFilter())
    }
}
