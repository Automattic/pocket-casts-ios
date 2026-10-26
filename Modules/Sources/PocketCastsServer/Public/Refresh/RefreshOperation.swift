import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class RefreshOperation: Operation, @unchecked Sendable {
    private var refreshResult: RefreshResult

    private var completionHandler: ((RefreshFetchResult) -> Void)?

    private let createdDate = Date()

    /// The sync that ran before this operation, if the refresh didn't wait for it.
    private let previousSync: SyncOperation?

    private var currentSync: SyncOperation?

    init(result: RefreshResult, previousSync: SyncOperation? = nil, completionHandler: ((RefreshFetchResult) -> Void)?) {
        refreshResult = result
        self.previousSync = previousSync
        self.completionHandler = completionHandler
        super.init()
    }

    override func cancel() {
        super.cancel()
        currentSync?.cancel()
    }

    override func main() {
        autoreleasepool {
            if isCancelled {
                return
            }

            let trace = TraceManager.shared.beginTracing(eventName: "SERVER_REFRESH")
            defer { TraceManager.shared.endTracing(trace: trace) }

            FileLog.shared.addMessage("Refresh - Processing response after waiting \(createdDate.elapsedTimeDescription) in the queue")

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
                return
            }

            // refresh is done, now perform a sync if the user has a sync account and it didn't already run
            var sync = previousSync
            if sync == nil, SyncManager.isUserLoggedIn() {
                let syncOperation = SyncOperation()
                currentSync = syncOperation
                syncOperation.start()
                sync = syncOperation
            }

            if let sync, !sync.succeeded {
                completionHandler?(.failed)
            } else {
                // we use the refresh to indicate to iOS whether we found new stuff or not
                completionHandler?(refreshResult == .successNewData ? .newData : .noData)
            }

            let afterSyncStartDate = Date()

            ServerConfig.shared.syncDelegate?.applyAutoArchivingToAllPodcasts()

            processAutoAddUpNextCandidates()

            ServerConfig.shared.syncDelegate?.performActionsAfterSync()

            FileLog.shared.addMessage("Refresh - Finished the work after sync in \(afterSyncStartDate.elapsedTimeDescription)")
        }
    }

    func performRefresh() -> UpdateStatus {
        if isCancelled {
            return .cancelled
        }

        let startDate = Date()
        var newEpisodesAdded = 0

        // the returned dictionary is indexed by podcast UUID and contains all the new episodes for that podcast
        let podcasts = DataManager.shared.allPodcasts(includeUnsubscribed: false)
        let updatedPodcasts = refreshResult.podcastUpdates
        var receivedEpisodes = [(podcast: Podcast, episodes: [Episode])]()
        for podcast in podcasts {
            guard let podcastEpisodes = updatedPodcasts?[podcast.uuid], !podcastEpisodes.isEmpty else { continue }

            let episodes: [Episode] = podcastEpisodes.reversed().compactMap({ episode in
                guard episode.uuid != nil else { return nil }

                let newEpisode = Episode()
                newEpisode.podcast_id = podcast.id
                newEpisode.podcastUuid = podcast.uuid
                newEpisode.playingStatus = PlayingStatus.notPlayed.rawValue
                newEpisode.episodeStatus = DownloadStatus.notDownloaded.rawValue
                newEpisode.addedDate = Date()
                newEpisode.populate(fromEpisode: episode)
                return newEpisode
            })
            receivedEpisodes.append((podcast, episodes))
        }

        let allReceivedEpisodes = receivedEpisodes.flatMap(\.episodes)
        let savedUuids = Set(DataManager.shared.insertEpisodesIfMissing(allReceivedEpisodes).map(\.uuid))
        // the sync can save a new episode from Up Next with only its title and URL before the refresh gets to it
        DataManager.shared.fillMissingDetails(from: allReceivedEpisodes.filter { !savedUuids.contains($0.uuid) })

        var metadataRequestsQueued = 0
        for (podcast, receivedPodcastEpisodes) in receivedEpisodes {
            let episodes = receivedPodcastEpisodes.filter { savedUuids.contains($0.uuid) }
            for episode in episodes {
                if isCancelled {
                    return .cancelled
                }

                // store episodes that we might possibly add to Up Next for processing after a sync
                if podcast.autoAddToUpNextOn() {
                    DataManager.shared.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)
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
            ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: false)
        }

        ServerConfig.shared.syncDelegate?.checkForUnusedPodcasts()
        ServerConfig.shared.syncDelegate?.cleanupAllUnusedEpisodeBuffers()

        UserDefaults.standard.set(Date(), forKey: ServerConstants.UserDefaults.lastRefreshEndTime)

        FileLog.shared.addMessage("Refresh complete found \(newEpisodesAdded) new episodes in \(startDate.elapsedTimeDescription)")

        return (newEpisodesAdded > 0) ? .successNewData : .successNoNewData
    }

    private func processAutoAddUpNextCandidates() {
        // look through our candidate episodes that are new and should be added to Up Next, and add any that haven't been played or archived as part of the sync
        let upNextLimit = ServerSettings.autoAddToUpNextLimit()

        let autoAddCandidates = DataManager.shared.autoAddCandidates.candidates()

        if !autoAddCandidates.isEmpty {
            let startingCount = ServerConfig.shared.playbackDelegate?.upNextQueueCount ?? 0
            FileLog.shared.addMessage("Checking for auto add to up next episodes in \(autoAddCandidates.count) podcasts that have been updated with auto add to up next turned on limit is \(upNextLimit) starting count is \(startingCount)")
        }

        for candidate in autoAddCandidates {
            // Ignore any podcasts that no longer have the setting enabled
            guard candidate.autoAddToUpNextSetting != .off else {
                continue
            }

            let episodeUuid = candidate.episodeUuid
            let toTop = candidate.autoAddToUpNextSetting == .addFirst

            guard let episode = DataManager.shared.findEpisode(uuid: episodeUuid), !episode.played(), !episode.archived, let inUpNext = ServerConfig.shared.playbackDelegate?.inUpNext(episode: episode), inUpNext == false else { continue }

            let currentCount = ServerConfig.shared.playbackDelegate?.upNextQueueCount ?? 0
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
            DataManager.shared.autoAddCandidates.remove(candidate)
        }

        // We have finished processing all of the up next candidates.
        //
        // There is a chance that some candidates are invalid and were not processed. We'll solve this by deleting all
        // of the candidates from the DB to ensure there are no ghost episodes left over.
        DataManager.shared.autoAddCandidates.clearAll()
    }
}
