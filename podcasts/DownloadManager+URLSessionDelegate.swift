import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
    // things smaller than 10kbs are not episodes, way too small and something has gone wrong
    private static let badEpisodeSize = 10 * 1024

    // things smaller than 150kb are suspect, probably text, xml or html error pages
    private static let suspectEpisodeSize = 150 * 1024

    // make sure to call the completion handler on the main queue, otherwise it will crash
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
#if os(watchOS)
        DispatchQueue.main.async { [weak self] in
            guard let self, let task = pendingWatchBackgroundTask else { return }

            task.setTaskCompletedWithSnapshot(true)
        }
#else
        DispatchQueue.main.async { [weak self] in
            guard let self, let appDelegate = appDelegate(), let backgroundHandler = appDelegate.backgroundSessionCompletionHandler else { return }

            appDelegate.backgroundSessionCompletionHandler = nil
            backgroundHandler()
        }
#endif
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let downloadingEpisode = episodeForTask(downloadTask, forceReload: false) else { return }

        let downloadingToStream = downloadingEpisode.autoDownloadStatus == AutoDownloadStatus.playerDownloadedForStreaming.rawValue
        if !downloadingToStream {
            progressManager.updateProgressForEpisode(downloadingEpisode.uuid, totalBytesWritten: totalBytesWritten, totalBytesExpected: totalBytesExpectedToWrite)
        }

        // If our download status or downloadTaskId are incorrect, then we should update these
        if !downloadingEpisode.downloading() || downloadingEpisode.downloadTaskId == nil {
            if let httpResponse = downloadTask.response as? HTTPURLResponse, let episode = downloadingEpisode as? Episode {
                MetadataUpdater.shared.updateMetadataFrom(response: httpResponse, episode: episode)
            }

            if !downloadingToStream {
                // Reuse our downloadTaskID if we have one, otherwise let the method set a default based on the episode
                if let downloadTaskId = downloadingEpisode.downloadTaskId {
                    dataManager.saveEpisode(downloadStatus: .downloading, sizeInBytes: totalBytesExpectedToWrite, downloadTaskId: downloadTaskId, episode: downloadingEpisode)
                } else {
                    dataManager.saveEpisode(downloadStatus: .downloading, sizeInBytes: totalBytesExpectedToWrite, episode: downloadingEpisode)
                }
                progressManager.updateStatusForEpisode(downloadingEpisode.uuid, status: .downloading)
            }
        }
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as NSError?, let task = task as? URLSessionDownloadTask else {
            // if there's no error then no need for us to do anything
            return
        }

        // check for ones we cancelled
        guard let episode = episodeForTask(task, forceReload: true) else { return } // we no longer have this episode
        removeEpisodeFromCache(episode)

        switch error.code {
        case NSURLErrorCancelled:
            if !episode.downloadFailed() {
                // we already handled this error, since we failed the download ourselves
                let reason = error.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] as? Int
                switch reason {
                case NSURLErrorCancelledReasonUserForceQuitApplication, NSURLErrorCancelledReasonInsufficientSystemResources:
                    dataManager.saveEpisode(downloadStatus: .queued, downloadTaskId: nil, episode: episode)
                default:
                    ()
                }
            } else {
                // this download was cancelled by us so it should have been due to user cancellation
                dataManager.saveEpisode(downloadStatus: .notDownloaded, downloadTaskId: nil, episode: episode)
            }

            return
        case NSURLErrorTimedOut:
            taskFailure[episode.uuid] = .connectionTimeout
        case NSURLErrorCannotConnectToHost:
            taskFailure[episode.uuid] = .unknownHost
        default:
            ()
        }

        dataManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: error.localizedDescription, downloadTaskId: nil, episode: episode)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let episode = episodeForTask(downloadTask, forceReload: true) else { return }

        removeEpisodeFromCache(episode)
        guard let response = downloadTask.response as? HTTPURLResponse else {
            // invalid download since we can't check things like the status code and headers if it's not a HTTPURLResponse
            markEpisode(episode, asFailedWithMessage: L10n.downloadFailed, reason: .badResponse)
            return
        }

        if response.statusCode >= 400, response.statusCode < 600 {
            let message: String
            if response.statusCode == ServerConstants.HttpConstants.notFound {
                message = L10n.downloadErrorContactAuthorVersion2
            } else {
                message = L10n.downloadErrorStatusCode(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))
            }

            // invalid download
            markEpisode(episode, asFailedWithMessage: message, reason: .statusCode(response.statusCode))
            return
        }

        let contentType = response.allHeaderFields[ServerConstants.HttpHeaders.contentType] as? String
        let fileSize = FileManager.default.fileSize(of: location) ?? 0
        guard isEpisodeFileValid(contentType: contentType, fileSize: fileSize) else {
            markEpisode(episode, asFailedWithMessage: L10n.downloadErrorContactAuthorVersion2, reason: .suspiciousContent(fileSize))
            return
        }

        let autoDownloadStatus = AutoDownloadStatus(rawValue: episode.autoDownloadStatus)!
        let destinationPath = autoDownloadStatus == .playerDownloadedForStreaming ? streamingBufferPathForEpisode(episode) : pathForEpisode(episode)
        let destinationUrl = URL(fileURLWithPath: destinationPath)
        do {
            try StorageManager.moveItem(at: location, to: destinationUrl, options: .overwriteExisting)

            let newDownloadStatus: DownloadStatus = autoDownloadStatus == .playerDownloadedForStreaming ? .downloadedForStreaming : .downloaded
            dataManager.saveEpisode(downloadStatus: newDownloadStatus, sizeInBytes: fileSize, downloadTaskId: nil, episode: episode)

            EpisodeFileSizeUpdater.updateEpisodeDuration(episode: episode)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloaded, object: episode.uuid)
        } catch {
            markEpisode(episode, asFailedWithMessage: L10n.downloadErrorNotEnoughSpace, reason: .badResponse)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let episode = episodeForTask(downloadTask, forceReload: false) else {
            return
        }

        if let failure = taskFailure[episode.uuid] {
            logDownload(episode, failure: failure, metrics: metrics, session: session)
            taskFailure.removeValue(forKey: episode.uuid)
        }

        let taskId = episode.downloadTaskId ?? episode.uuid
        downloadingEpisodesCache.removeValue(forKey: taskId)
    }

    private func episodeForTask(_ task: URLSessionDownloadTask, forceReload: Bool) -> BaseEpisode? {
        guard let downloadId = task.taskDescription else { return nil }

        if !forceReload {
            if let episode = downloadingEpisodesCache[downloadId] {
                return episode
            }
        }

        let episode = dataManager.findBaseEpisode(downloadTaskId: downloadId)
        if let episode = episode {
            downloadingEpisodesCache[downloadId] = episode
        }

        return episode
    }

    enum FailureReason: Error {
        case badResponse
        case statusCode(Int)
        case suspiciousContent(Int64)
        case notEnoughSpace
        case connectionTimeout
        case unknownHost
        case malformedHost
        case unknown(NSError)

        var localizedDescription: String {
            switch self {
            case .badResponse:
                return "bad_response"
            case .statusCode:
                return "status_code"
            case .suspiciousContent:
                return "suspicious_content"
            case .notEnoughSpace:
                return "not_enough_storage"
            case .connectionTimeout:
                return "connection_timeout"
            case .unknownHost:
                return "unknown_host"
            case .malformedHost:
                return "malformed_host"
            case .unknown:
                return "unknown"
            }
        }
    }

    func isEpisodeFileValid(contentType: String?, fileSize: Int64) -> Bool {
        // basic sanity checks to make sure the file looks big enough and it's content type isn't text
        if fileSize < DownloadManager.badEpisodeSize || (fileSize < DownloadManager.suspectEpisodeSize && contentType?.contains("text") ?? false) {
            return false
        }

        return true
    }

    private func markEpisode(_ episode: BaseEpisode, asFailedWithMessage message: String, reason: FailureReason) {
        removeEpisodeFromCache(episode)

        dataManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: message, downloadTaskId: nil, episode: episode)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)

        taskFailure[episode.uuid] = reason
    }
}
