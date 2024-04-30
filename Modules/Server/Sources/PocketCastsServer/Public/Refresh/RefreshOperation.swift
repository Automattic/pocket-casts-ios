import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class RefreshOperation: Operation {
    private var refreshResult: RefreshResult

    private var completionHandler: ((RefreshFetchResult) -> Void)?

    private lazy var apiQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    init(result: RefreshResult, completionHandler: ((RefreshFetchResult) -> Void)?) {
        refreshResult = result
        self.completionHandler = completionHandler
        super.init()
    }

    override func main() {
        autoreleasepool {
            if isCancelled {
                cleanupAfterCancel()

                return
            }

            let trace = TraceManager.shared.beginTracing(eventName: "SERVER_REFRESH")
            defer { TraceManager.shared.endTracing(trace: trace) }

            // look for new podcasts from the server
            let refreshResult = performRefresh()

            // if this operation fails, or our operation was cancelled, let the completion handler know and stop
            if refreshResult == .failed || refreshResult == .cancelled {
                FileLog.shared.addMessage("Refresh \(refreshResult == .failed ? "failed" : "was cancelled")")
                ServerNotificationsHelper.shared.firePodcastRefreshFailed()
                completionHandler?(.failed)
                return
            }

            // let various bits of the app know we have finished the refresh
            ServerNotificationsHelper.shared.firePodcastRefreshSucceeded()

            if isCancelled {
                cleanupAfterCancel()

                return
            }

            // refresh is done, now perform a sync if the user has a sync account
            if SyncManager.isUserLoggedIn() {
                NotificationCenter.default.post(name: ServerNotifications.syncStarted, object: nil)

                if SubscriptionHelper.hasActiveSubscription() { apiQueue.addOperation(RetrieveCustomFilesTask()) }
                apiQueue.addOperation(UpNextSyncTask())
                let syncTask = SyncTask()
                apiQueue.addOperation(syncTask)

                apiQueue.addOperation(SyncHistoryTask())

                apiQueue.addOperation(SyncSettingsTask())

                #if !os(watchOS)
                    ServerSettings.iapUnverifiedPurchaseReceiptDate() == nil ? apiQueue.addOperation(SubscriptionStatusTask()) : apiQueue.addOperation(PurchaseReceiptTask())
                #endif

                #if !os(watchOS)
                    // update our local copy of the remote stats. Doesn't really matter if this fails or succeeds
                    StatsManager.shared.loadRemoteStats(completion: nil)
                #endif

                apiQueue.waitUntilAllOperationsAreFinished()

                // we use the sync task as the main indication of whether the sync has failed
                let syncResult = syncTask.status
                if syncResult == .failed || syncResult == .cancelled {
                    completionHandler?(.failed)
                } else {
                    // however we use the refresh to indicate to iOS whether we found new stuff or not
                    completionHandler?(refreshResult == .successNewData ? .newData : .noData)

                    FileLog.shared.addMessage("Sync succeeded")

                    ServerNotificationsHelper.shared.fireSyncCompleted()
                    ServerConfig.shared.syncDelegate?.filterChanged()
                }
            } else { // no sync required, we're done
                completionHandler?(refreshResult == .successNewData ? .newData : .noData)
            }

            ServerConfig.shared.syncDelegate?.applyAutoArchivingToAllPodcasts()

            processAutoAddUpNextCandidates()

            ServerConfig.shared.syncDelegate?.performActionsAfterSync()
        }
    }

    func performRefresh() -> UpdateStatus {
        if isCancelled {
            cleanupAfterCancel()

            return .cancelled
        }

        var newEpisodesAdded = 0

        // the returned dictionary is indexed by podcast UUID and contains all the new episodes for that podcast
        let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        let updatedPodcasts = refreshResult.podcastUpdates
        var metadataRequestsQueued = 0
        for (idx, podcast) in podcasts.enumerated() {
            guard let podcastEpisodes = updatedPodcasts?[podcast.uuid], podcastEpisodes.count > 0 else { continue }

            let episodes: [Episode] = podcastEpisodes.reversed().compactMap({ episode in
                guard let episodeUuid = episode.uuid else { return nil }
                //TODO: hasEpisode?
                if let _ = DataManager.sharedManager.findEpisode(uuid: episodeUuid) { return nil }

                let newEpisode = Episode()
                newEpisode.podcast_id = podcast.id
                newEpisode.podcastUuid = podcast.uuid
                newEpisode.playingStatus = PlayingStatus.notPlayed.rawValue
                newEpisode.episodeStatus = DownloadStatus.notDownloaded.rawValue
                newEpisode.addedDate = Date()
                newEpisode.populate(fromEpisode: episode)
                return newEpisode
            })

            DataManager.sharedManager.bulkSave(episodes: episodes)

            for episode in episodes {
                if isCancelled {
                    cleanupAfterCancel()

                    return .cancelled
                }

                // store episodes that we might possibly add to Up Next for processing after a sync
                if podcast.autoAddToUpNextOn() {
                    DataManager.sharedManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)
                }

                #if !os(watchOS)
                    // so we don't flood the users phone, set a limit on the amount of meta data requests made. So if they open it after
                    // 4 weeks of not using it doesn't sit there for years
                    if metadataRequestsQueued < 10 {
                        MetadataUpdater.shared.updatedMetadata(episodeUuid: episode.uuid)
                        metadataRequestsQueued += 1
                    }
                #endif
            }

            newEpisodesAdded += episodes.count

            // there's at least one new episode, so update the latestEpisodeUuid
            ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: false, cache: idx == podcasts.endIndex)
        }

        ServerConfig.shared.syncDelegate?.checkForUnusedPodcasts()
        ServerConfig.shared.syncDelegate?.cleanupAllUnusedEpisodeBuffers()

        UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.lastRefreshEndTime)

        FileLog.shared.addMessage("Refresh complete found \(newEpisodesAdded) new episodes")

        return (newEpisodesAdded > 0) ? .successNewData : .successNoNewData
    }

    private func cleanupAfterCancel() {
        apiQueue.cancelAllOperations()
    }

    private func processAutoAddUpNextCandidates() {
        // look through our candidate episodes that are new and should be added to Up Next, and add any that haven't been played or archived as part of the sync
        let upNextLimit = ServerSettings.autoAddToUpNextLimit()

        let autoAddCandidates = DataManager.sharedManager.autoAddCandidates.candidates()

        if autoAddCandidates.count > 0 {
            let startingCount = ServerConfig.shared.playbackDelegate?.upNextQueueCount() ?? 0
            FileLog.shared.addMessage("Checking for auto add to up next episodes in \(autoAddCandidates.count) podcasts that have been updated with auto add to up next turned on limit is \(upNextLimit) starting count is \(startingCount)")
        }

        for candidate in autoAddCandidates {
            // Ignore any podcasts that no longer have the setting enabled
            guard candidate.autoAddToUpNextSetting != .off else {
                continue
            }

            let episodeUuid = candidate.episodeUuid
            let toTop = candidate.autoAddToUpNextSetting == .addFirst

            guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid), !episode.played(), !episode.archived, let inUpNext = ServerConfig.shared.playbackDelegate?.inUpNext(episode: episode), inUpNext == false else { continue }

            let currentCount = ServerConfig.shared.playbackDelegate?.upNextQueueCount() ?? 0
            if currentCount < upNextLimit {
                FileLog.shared.addMessage("Current Up Next count \(currentCount) is less than the limit, adding \(episode.displayableTitle()) to the \(toTop ? "top" : "bottom") of Up Next")
                ServerConfig.shared.playbackDelegate?.addToUpNext(episode: episode, ignoringQueueLimit: false, toTop: toTop)
            } else if toTop, ServerSettings.onAutoAddLimitReached() == .addToTopOnly {
                FileLog.shared.addMessage("Current Up Next count \(currentCount) is over the limit but still adding \(episode.displayableTitle()) to the top of the list")
                ServerConfig.shared.playbackDelegate?.removeLastEpisodeFromUpNext()
                ServerConfig.shared.playbackDelegate?.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: toTop)
            } else {
                FileLog.shared.addMessage("Current Up Next count \(currentCount) is over the limit not adding episode \(episode.displayableTitle())")
            }

            // The candidate has been processed, remove it from the database
            DataManager.sharedManager.autoAddCandidates.remove(candidate)
        }

        // We have finished processing all of the up next candidates.
        //
        // There is a chance that some candidates are invalid and were not processed. We'll solve this by deleting all
        // of the candidates from the DB to ensure there are no ghost episodes left over.
        DataManager.sharedManager.autoAddCandidates.clearAll()
    }
}
