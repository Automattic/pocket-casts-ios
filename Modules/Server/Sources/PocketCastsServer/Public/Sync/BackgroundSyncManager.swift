import Foundation
import PocketCastsDataModel
import PocketCastsUtils

#if os(watchOS)
    import WatchKit
#endif

public class BackgroundSyncManager: NSObject {
    public static let sessionIdPrefix = "SyncBgSession"

    public static let shared = BackgroundSyncManager()

    #if os(watchOS)
        var pendingWatchBackgroundTask: WKURLSessionRefreshBackgroundTask?
        public func processBackgroundTaskCallback(task: WKURLSessionRefreshBackgroundTask, identifier: String) {
            pendingWatchBackgroundTask = task
            _ = createUrlSession(identifier: identifier)
        }
    #endif

    let refreshTaskId = "refresh"
    let upNextSyncTaskId = "upnext"
    let syncTaskId = "sync"
    var lastBgSyncDate: Date?

    var haveProcessedRefresh = false
    var pendingSyncData: Data?
    var pendingSyncHttpCode: Int?
    var pendingUpNextSyncData: Data?
    var lastUpNextActionTime: Int64 = 0

    // we retain these so they aren't immediately released on method exit
    var pendingTasks = [URLSessionDownloadTask]()

    lazy var syncProcessQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    public func performBackgroundRefresh(subscribedPodcasts: [Podcast]) {
        guard DateUtil.hasEnoughTimePassed(since: lastBgSyncDate, time: 5.minutes) else { return }
        lastBgSyncDate = Date()

        // a background refresh only does the essential things to keep the app up to date, a regular refresh is:
        // Refresh, Retrieve Custom Files, Up Next Sync, Regular Sync, History Sync, Settings Sync

        // For this cut down version we just want:
        // Refresh, Up Next Sync, Regular Sync

        // we also need to perform all these on the same URLSession as download tasks, so the app can be put to sleep and woken up when they are done later

        let urlSession = createUrlSession(identifier: BackgroundSyncManager.sessionIdPrefix + UUID().uuidString)
        guard let token = try? KeychainHelper.string(for: ServerConstants.Values.syncingV2TokenKey), let refreshTask = refreshDownloadTask(subscribedPodcasts: subscribedPodcasts, urlSession: urlSession), let upNextTask = upNextDownloadTask(token: token, urlSession: urlSession), let syncTask = syncDownloadTask(token: token, urlSession: urlSession) else {
            FileLog.shared.addMessage("Unable to create tasks required to perform background refresh")

            return
        }

        FileLog.shared.addMessage("BackgroundSyncManager calling refresh, sync and up next sync")
        // kick off all the tasks, we'll process them in the URLSessionDelegate methods
        refreshTask.resume()
        pendingTasks.append(refreshTask)

        upNextTask.resume()
        pendingTasks.append(upNextTask)

        syncTask.resume()
        pendingTasks.append(syncTask)
    }

    private func refreshDownloadTask(subscribedPodcasts: [Podcast], urlSession: URLSession) -> URLSessionDownloadTask? {
        guard let request = MainServerHandler.shared.createRefreshRequest(podcasts: subscribedPodcasts) else { return nil }

        let task = urlSession.downloadTask(with: request)
        task.countOfBytesClientExpectsToSend = Int64(10.kilobytes)
        task.countOfBytesClientExpectsToReceive = Int64(50.kilobytes)
        task.taskDescription = refreshTaskId

        return task
    }

    private func upNextDownloadTask(token: String, urlSession: URLSession) -> URLSessionDownloadTask? {
        guard let upNextRequest = UpNextSyncTask().createUpNextUrlRequest(token: token) else {
            return nil
        }

        let task = urlSession.downloadTask(with: upNextRequest.urlRequest)
        task.countOfBytesClientExpectsToSend = Int64(50.kilobytes)
        task.countOfBytesClientExpectsToReceive = Int64(50.kilobytes)
        task.taskDescription = upNextSyncTaskId
        lastUpNextActionTime = upNextRequest.latestActionTime

        return task
    }

    private func syncDownloadTask(token: String, urlSession: URLSession) -> URLSessionDownloadTask? {
        guard let request = SyncTask().incrementalSyncRequest(token: token) else {
            return nil
        }

        let task = urlSession.downloadTask(with: request)
        task.countOfBytesClientExpectsToSend = Int64(50.kilobytes)
        task.countOfBytesClientExpectsToReceive = Int64(50.kilobytes)
        task.taskDescription = syncTaskId

        return task
    }

    private func createUrlSession(identifier: String) -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        return session
    }
}
