import Foundation
#if !os(watchOS)
    import FirebaseCrashlytics
#endif
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
                guard let self = self, let task = self.pendingWatchBackgroundTask else { return }

                task.setTaskCompletedWithSnapshot(true)
            }
        #else
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self, let appDelegate = strongSelf.appDelegate(), let backgroundHandler = strongSelf.appDelegate()?.backgroundSessionCompletionHandler else { return }

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

        if !downloadingEpisode.downloading(), downloadingEpisode.downloadTaskId != nil {
            if let httpResponse = downloadTask.response as? HTTPURLResponse, let episode = downloadingEpisode as? Episode {
                MetadataUpdater.shared.updateMetadataFrom(response: httpResponse, episode: episode)
            }

            if !downloadingToStream {
                DataManager.sharedManager.saveEpisode(downloadStatus: .downloading, sizeInBytes: totalBytesExpectedToWrite, episode: downloadingEpisode)
                progressManager.updateStatusForEpisode(downloadingEpisode.uuid, status: .downloading)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {}

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as NSError?, let task = task as? URLSessionDownloadTask else {
            // if there's no error then no need for us to do anything
            return
        }

        // check for ones we cancelled
        guard let episode = episodeForTask(task, forceReload: true) else { return } // we no longer have this episode
        removeEpisodeFromCache(episode)

        if error.code == NSURLErrorCancelled {
            if !episode.downloadFailed() {
                // already handled this error, since we failed the download ourselves
            } else {
                DataManager.sharedManager.saveEpisode(downloadStatus: .notDownloaded, downloadTaskId: nil, episode: episode)
            }

            return
        } else if error.code != NSURLErrorNotConnectedToInternet {
            if Settings.analyticsOptOut() == false {
                #if !os(watchOS)
                Crashlytics.crashlytics().record(error: error)
                #endif
            }
        }

        DataManager.sharedManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: error.localizedDescription, downloadTaskId: nil, episode: episode)

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

        let fileManager = FileManager.default
        var fileSize: Int64 = 0
        do {
            let attrs = try fileManager.attributesOfItem(atPath: location.path)
            if let computedSize = attrs[.size] as? Int64 {
                fileSize = computedSize
            }
            let contentType = response.allHeaderFields[ServerConstants.HttpHeaders.contentType] as? String
            // basic sanity checks to make sure the file looks big enough and it's content type isn't text
            if fileSize < DownloadManager.badEpisodeSize || (fileSize < DownloadManager.suspectEpisodeSize && contentType?.contains("text") ?? false) {
                markEpisode(episode, asFailedWithMessage: L10n.downloadErrorContactAuthorVersion2, reason: .episodeSize(fileSize))

                return
            }
        } catch {}

        let autoDownloadStatus = AutoDownloadStatus(rawValue: episode.autoDownloadStatus)!
        let destinationPath = autoDownloadStatus == .playerDownloadedForStreaming ? streamingBufferPathForEpisode(episode) : pathForEpisode(episode)
        let destinationUrl = URL(fileURLWithPath: destinationPath)
        do {
            try StorageManager.moveItem(at: location, to: destinationUrl, options: .overwriteExisting)

            let newDownloadStatus: DownloadStatus = autoDownloadStatus == .playerDownloadedForStreaming ? .downloadedForStreaming : .downloaded
            DataManager.sharedManager.saveEpisode(downloadStatus: newDownloadStatus, sizeInBytes: fileSize, downloadTaskId: nil, episode: episode)

            EpisodeFileSizeUpdater.updateEpisodeDuration(episode: episode)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloaded, object: episode.uuid)
        } catch {
            markEpisode(episode, asFailedWithMessage: L10n.downloadErrorNotEnoughSpace, reason: .badResponse)
        }
    }

    private func episodeForTask(_ task: URLSessionDownloadTask, forceReload: Bool) -> BaseEpisode? {
        guard let downloadId = task.taskDescription else { return nil }

        if !forceReload {
            if let episode = downloadingEpisodesCache[downloadId] {
                return episode
            }
        }

        let episode = DataManager.sharedManager.findBaseEpisode(downloadTaskId: downloadId)
        if let episode = episode {
            downloadingEpisodesCache[downloadId] = episode
        }

        return episode
    }

    enum FailureReason: Error {
        case badResponse
        case statusCode(Int)
        case episodeSize(Int64)
        case notEnoughSpace

        var localizedDescription: String {
            switch self {
            case .badResponse:
                return "Bad Response"
            case .statusCode(let statusCode):
                return "Status Code: \(statusCode)"
            case .episodeSize(let size):
                return "Episode Size: \(size)"
            case .notEnoughSpace:
                return "Not Enough Space"
            }
        }
    }

    private func markEpisode(_ episode: BaseEpisode, asFailedWithMessage message: String, reason: FailureReason) {
        removeEpisodeFromCache(episode)

        DataManager.sharedManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: message, downloadTaskId: nil, episode: episode)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)

        AnalyticsEpisodeHelper.shared.downloadFailed(episodeUUID: episode.uuid, reason: reason.localizedDescription)
    }
}
