import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class DownloadProgressManager {
    private var progressItems = [String: DownloadProgress]()
    private let progressItemsQueue: DispatchQueue

    private var finishedItemCount: Double = 0

    init() {
        progressItemsQueue = DispatchQueue(label: "au.com.pocketcasts.ProgressItemsQueue")
    }

    func progressForEpisode(_ uuid: String) -> DownloadProgress? {
        progressItemsQueue.sync {
            progressItems[uuid]
        }
    }

    func updateProgressForEpisode(_ uuid: String, totalBytesWritten: Int64, totalBytesExpected: Int64) {
        var update: Bool = false
        progressItemsQueue.sync {
            var progressItem: DownloadProgress
            if let existing = progressItems[uuid] {
                progressItem = existing
            } else {
                progressItem = DownloadProgress()
                finishedItemCount = 0
            }

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

    func updateStatusForEpisode(_ uuid: String, status: DownloadStatus) {
        progressItemsQueue.sync {
            var progressItem = progressItems[uuid]
            if progressItem == nil {
                progressItem = DownloadProgress()
                finishedItemCount = 0
            }

            progressItem?.status = status
            progressItems[uuid] = progressItem!
        }
    }

    func removeProgressForEpisode(_ uuid: String) {
        progressItemsQueue.sync {
            finishedItemCount += 1
            progressItems.removeValue(forKey: uuid)
        }
    }
}
