import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class FilterManager {
    class func checkForAutoDownloads() {
        let filters = DataManager.sharedManager.allFilters(includeDeleted: false)

        if filters.count == 0 { return }

        let onWifi = NetworkUtils.shared.isConnectedToWifi()
        let mobileDataAllowed = Settings.autoDownloadMobileDataAllowed()
        for filter in filters {
            guard filter.autoDownloadEpisodes else { continue }

            let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Int(filter.maxAutoDownloadEpisodes()))
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
        let filters = DataManager.sharedManager.allFilters(includeDeleted: false)
        if filters.count == 0 { return }

        for filter in filters {
            guard !filter.filterAllPodcasts, filter.podcastUuids.count > 0 else { continue }

            var podcastUuids = filter.podcastUuids.components(separatedBy: ",")
            guard let indexOfUuid = podcastUuids.firstIndex(of: podcastUuid) else { continue }

            podcastUuids.remove(at: indexOfUuid)
            filter.podcastUuids = podcastUuids.joined(separator: ",")
            if SyncManager.isUserLoggedIn() { filter.syncStatus = SyncStatus.notSynced.rawValue }
            DataManager.sharedManager.save(filter: filter)
        }
    }

    class func autoDownloadFilterCount() -> Int {
        let filters = DataManager.sharedManager.allFilters(includeDeleted: false)

        return filters.filter { episodeFilter -> Bool in
            episodeFilter.autoDownloadEpisodes
        }.count
    }
}
