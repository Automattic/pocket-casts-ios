import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class DownloadProgressManager {
    private let progressItems = Mutex([String: DownloadProgress]())

    func progress(forEpisodeUuid uuid: String) -> DownloadProgress? {
        progressItems.withLock { progressItems in
            progressItems[uuid]
        }
    }

    func updateProgress(forEpisodeUuid uuid: String, totalBytesWritten: Int64, totalBytesExpected: Int64) {
        var update: Bool = false
        progressItems.withLock { progressItems in
            var progressItem = progressItems[uuid] ?? DownloadProgress()

            progressItem.totalToDownload = totalBytesExpected
            progressItem.downloadedSoFar = totalBytesWritten

            // throttle updates to once every 1s so we don't flood the UI thread
            if progressItem.lastUiUpdateTime.timeIntervalSinceNow < -1 {
                progressItem.lastUiUpdateTime = Date()
                update = true
            }

            progressItems[uuid] = progressItem
        }
        if update {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.downloadProgress, object: uuid)
        }
    }

    func updateStatus(forEpisodeUuid uuid: String, status: DownloadStatus) {
        progressItems.withLock { progressItems in
            var progressItem = progressItems[uuid] ?? DownloadProgress()
            progressItem.status = status
            progressItems[uuid] = progressItem
        }
    }

    func removeProgress(forEpisodeUuid uuid: String) {
        progressItems.withLock { progressItems in
            progressItems[uuid] = nil
        }
    }
}
