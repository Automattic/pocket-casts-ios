import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

public class ApiServerHandler {
    public static let shared = ApiServerHandler()

    lazy var apiQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    private var lastUpToSaved: Date?
    public class func saveUpTo(time: TimeInterval, duration: TimeInterval, episode: BaseEpisode) {
        if let lastSaved = shared.lastUpToSaved, let minTimeBetweenProgressSaves = ServerConfig.shared.syncDelegate?.minTimeBetweenProgressSaves(), fabs(lastSaved.timeIntervalSinceNow) < minTimeBetweenProgressSaves { return }

        shared.lastUpToSaved = Date()

        if let episode = episode as? Episode {
            let saveOperation = PositionSyncTask(upTo: time, duration: duration, episode: episode)
            shared.apiQueue.addOperation(saveOperation)
        } else if let userEpisode = episode as? UserEpisode, userEpisode.uploaded() {
            shared.uploadSingleFileUpdateRequest(episode: userEpisode, completion: { _ in })
        }
    }

    public func saveCompleted(episode: BaseEpisode) {
        if let episode = episode as? Episode {
            let saveOperation = PositionSyncTask(upTo: episode.playedUpTo, duration: episode.duration, episode: episode)
            apiQueue.addOperation(saveOperation)
        } else if let userEpisode = episode as? UserEpisode, userEpisode.uploaded() {
            uploadSingleFileUpdateRequest(episode: userEpisode, completion: { _ in })
        }
    }

    public func saveStarred(episode: Episode) {
        let operation = StarredSyncTask(episode: episode)
        apiQueue.addOperation(operation)
    }

    public func retrieveStarred(completion: @escaping ([Episode]?) -> Void) {
        let retrieveTask = RetrieveStarredTask()
        retrieveTask.completion = completion
        apiQueue.addOperation(retrieveTask)
    }

    public func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        let deleteAccountTask = DeleteAccountTask()
        deleteAccountTask.completion = completion
        apiQueue.addOperation(deleteAccountTask)
    }

    public func cancelPaidPodcastSubcription(bundleUuid: String, completion: @escaping (Bool) -> Void) {
        let cancelTask = CancelSubscriptionTask(bundleUuid: bundleUuid)
        cancelTask.completion = completion
        apiQueue.addOperation(cancelTask)

        // The server doesn't actually mark the subscription as cancelled until it gets the Paddle webhook. I'm reliable informed by Phil that 1 second is enough, so here we'll give it 4
        apiQueue.addOperation {
            Thread.sleep(forTimeInterval: 4.seconds)
        }

        // since the users subscriptions will have changed after the previous call, queue up a refresh
        let subscriptionStatusTask = SubscriptionStatusTask()
        apiQueue.addOperation(subscriptionStatusTask)
    }

    public func loadStatsRequest(completion: @escaping (RemoteStats?) -> Void) {
        let statsOperation = RetrieveStatsTask()
        statsOperation.completion = completion
        apiQueue.addOperation(statsOperation)
    }

    public func retrieveEpisodeTaskSynchronouusly(podcastUuid: String) -> ([EpisodeSyncInfo]?) {
        let retrieveTask = RetrieveEpisodesTask(podcastUuid: podcastUuid)
        var retrievedEpisodes: [EpisodeSyncInfo]?
        retrieveTask.completion = { episodes in
            retrievedEpisodes = episodes
        }
        retrieveTask.runTaskSynchronously()
        return retrievedEpisodes
    }

    public func syncSettings() {
        let syncSettingsTask = SyncSettingsTask()
        apiQueue.addOperation(syncSettingsTask)
    }

    public func reloadFoldersFromServer() {
        ServerSettings.setHomeGridNeedsRefresh(true)
        RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
    }

    public func processPendingCloudDeletes(episodes: [UserEpisode], deleteCompletedHandler: ((UserEpisode) -> Void)?) {
        FileLog.shared.addMessage("\(episodes.count) episodes pending to be cloud deleted, processing those now")
        for episode in episodes {
            let deleteOperation = UploadFileDeleteTask(episode: episode)
            deleteOperation.completion = { success in
                guard success else { return } // failed deletes will remain as pending

                DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, episode: episode)
                deleteCompletedHandler?(episode)
            }
            apiQueue.addOperation(deleteOperation)
        }
    }

    /// Swaps the current auth token with one scoped for use in Sonos connections
    /// - Returns: The auth token or nil if it failed for any reason
    public func exchangeSonosToken() async -> String? {
        let token = await withCheckedContinuation { continuation in
            let task = ExchangeSonosTask()

            task.completion = { token in
                continuation.resume(returning: token)
            }

            apiQueue.addOperation(task)
        }

        return token
    }
}
