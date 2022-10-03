import PocketCastsDataModel
import UIKit

class DownloadProgressManager {
    private var progressItems = [String: DownloadProgress]()
    private let progressItemsQueue: DispatchQueue

    private var finishedItemCount: Double = 0
    private var lastUiUpdateTime: Date?

    init() {
        progressItemsQueue = DispatchQueue(label: "au.com.pocketcasts.ProgressItemsQueue")
    }

    func progressForEpisode(_ uuid: String) -> DownloadProgress? {
        progressItemsQueue.sync {
            progressItems[uuid]
        }
    }

    func hasProgressForEpisode(_ uuid: String) -> Bool {
        progressItemsQueue.sync {
            progressItems[uuid] != nil
        }
    }

    func countOfDownloadingItems() -> Int {
        progressItemsQueue.sync {
            progressItems.count
        }
    }

    func totalProgressAsPercentage() -> Double {
        progressItemsQueue.sync {
            let downloadingCount = Double(progressItems.count)
            if downloadingCount == 0 { return 0 }

            var totalProgress: Double = 0
            for progressItem in progressItems {
                totalProgress += progressItem.value.percentageProgress()
            }
            totalProgress += (finishedItemCount * 100)

            return totalProgress / ((downloadingCount + finishedItemCount) * 100)
        }
    }

    func updateProgressForEpisode(_ uuid: String, totalBytesWritten: Int64, totalBytesExpected: Int64) {
        progressItemsQueue.sync {
            var progressItem = progressItems[uuid]
            if progressItem == nil {
                progressItem = DownloadProgress()
                finishedItemCount = 0
            }

            progressItem?.totalToDownload = totalBytesExpected
            progressItem?.downloadedSoFar = totalBytesWritten
            progressItems[uuid] = progressItem!
        }

        // throttle updates to once every 1s so we don't flood the UI thread
        if lastUiUpdateTime == nil || lastUiUpdateTime!.timeIntervalSinceNow < -1 {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.downloadProgress, object: uuid)
            lastUiUpdateTime = Date()
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
