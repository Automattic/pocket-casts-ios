import DataModel
import Foundation

extension SyncTask {
    func processServerFilters(_ filters: [EpisodeFilter]) {
        // before looking at the server filters, mark any we have here locally as needing to be syncing so they get pushed up with the next sync
        DataManager.sharedManager.markAllEpisodeFiltersUnsynced()

        for filter in filters {
            // if we have this filter locally, assume the server version is more up to date, so blow ours away
            if let localFilter = DataManager.sharedManager.findFilter(uuid: filter.uuid) {
                DataManager.sharedManager.delete(filter: localFilter)
            }

            // save the server version of the filter, as long as it's not deleted
            if !filter.wasDeleted {
                filter.syncStatus = SyncStatus.synced.rawValue
                DataManager.sharedManager.save(filter: filter)
            }
        }
    }

    func processServerPodcasts(_ podcasts: [PodcastSyncInfo]) {
        // before looking at the server podcasts, mark any we have here locally as needing to be syncing so they get pushed up with the next sync
        DataManager.sharedManager.markAllPodcastsUnsynced()

        totalToImport = podcasts.count
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.syncProgressPodcastCount, object: totalToImport)

        upToPodcast = 0
        for podcast in podcasts {
            importQueue.addOperation {
                self.upToPodcast += 1
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.syncProgressPodcastUpto, object: self.upToPodcast)

                self.processPodcast(podcast)
            }
        }
        importQueue.waitUntilAllOperationsAreFinished()

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.syncProgressImportedPodcasts)
    }

    func processPodcast(_ podcast: PodcastSyncInfo) {
        guard let uuid = podcast.uuid else { return }

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        PodcastManager.shared.addFromUuid(podcastUuid: uuid, subscribe: true) { success in
            if !success {
                dispatchGroup.leave()

                return
            }

            guard let localPodcast = DataManager.sharedManager.findPodcast(uuid: uuid) else { return }

            // we have added the podcast locally so add the synced info for it
            if let startFrom = podcast.autoStartFrom {
                localPodcast.startFrom = Int32(startFrom)
            }
            if let skipLast = podcast.autoSkipLast {
                localPodcast.skipLast = Int32(skipLast)
            }
            localPodcast.syncStatus = SyncStatus.synced.rawValue
            DataManager.sharedManager.save(podcast: localPodcast)

            // now grab the sync info for the episodes
            let retrieveEpisodesTask = RetrieveEpisodesTask(podcastUuid: uuid)
            retrieveEpisodesTask.completion = { episodes in
                guard let episodes = episodes else { return }

                DataManager.sharedManager.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
            }
            retrieveEpisodesTask.runTaskSynchronously()
            dispatchGroup.leave()
        }

        _ = dispatchGroup.wait(timeout: .now() + 30.seconds)
    }
}
