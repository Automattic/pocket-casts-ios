import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class RefreshOperation: Operation {
    private var refreshResult: RefreshResult

    private var completionHandler: ((RefreshFetchResult) -> Void)?

    private var addToUpNextCandidateEpisodes = [String: [String]]() // podcastUuid : [episodeUuid]

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

            // look through our candidate episodes that are new and should be added to Up Next, and add any that haven't been played or archived as part of the sync
            let upNextLimit = ServerSettings.autoAddToUpNextLimit()
            if addToUpNextCandidateEpisodes.keys.count > 0 {
                let startingCount = ServerConfig.shared.playbackDelegate?.upNextQueueCount() ?? 0
                FileLog.shared.addMessage("Checking for auto add to up next episodes in \(addToUpNextCandidateEpisodes.keys.count) podcasts that have been updated with auto add to up next turned on limit is \(upNextLimit) starting count is \(startingCount)")
            }
            for podcastUuid in addToUpNextCandidateEpisodes.keys {
                guard let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid) else { continue }

                for episodeUuid in addToUpNextCandidateEpisodes[podcastUuid] ?? [String]() {
                    guard let episode = DataManager.sharedManager.findEpisode(uuid: episodeUuid), !episode.played(), !episode.archived, let inUpNext = ServerConfig.shared.playbackDelegate?.inUpNext(episode: episode), inUpNext == false else { continue }

                    let toTop = podcast.autoAddToUpNext == AutoAddToUpNextSetting.addFirst.rawValue

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
                }
            }

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
        for podcast in podcasts {
            guard let podcastEpisodes = updatedPodcasts?[podcast.uuid], podcastEpisodes.count > 0 else { continue }

            for episode in podcastEpisodes.reversed() {
                if isCancelled {
                    cleanupAfterCancel()

                    return .cancelled
                }

                guard let episodeUuid = episode.uuid else { continue }
                if let _ = DataManager.sharedManager.findEpisode(uuid: episodeUuid) { continue }

                let newEpisode = Episode()
                newEpisode.podcast_id = podcast.id
                newEpisode.podcastUuid = podcast.uuid
                newEpisode.playingStatus = PlayingStatus.notPlayed.rawValue
                newEpisode.episodeStatus = DownloadStatus.notDownloaded.rawValue
                newEpisode.addedDate = Date()
                newEpisode.populate(fromEpisode: episode)
                DataManager.sharedManager.save(episode: newEpisode)

                newEpisodesAdded += 1

                // store episodes that we might possibly add to Up Next for processing after a sync
                if podcast.autoAddToUpNextOn() {
                    var newEpisodes = addToUpNextCandidateEpisodes[podcast.uuid] ?? [String]()
                    newEpisodes.append(newEpisode.uuid)
                    addToUpNextCandidateEpisodes[podcast.uuid] = newEpisodes
                }

                #if !os(watchOS)
                    // so we don't flood the users phone, set a limit on the amount of meta data requests made. So if they open it after
                    // 4 weeks of not using it doesn't sit there for years
                    if metadataRequestsQueued < 10 {
                        MetadataUpdater.shared.updatedMetadata(episodeUuid: newEpisode.uuid)
                        metadataRequestsQueued += 1
                    }
                #endif
            }

            // there's at least one new episode, so update the latestEpisodeUuid
            ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: false)
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
}
