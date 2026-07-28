import PocketCastsDataModel
import UIKit

public class UploadProgressManager: NSObject {
    private var progressItems = [String: UploadProgress]()
    private lazy var progressItemsQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "au.com.pocketcasts.UploadProgressItemsQueue")

        return queue
    }()

    private var finishedItemCount: Double = 0
    private var lastUiUpdateTime: Date?

    public func progressForEpisode(_ uuid: String) -> UploadProgress? {
        progressItemsQueue.sync {
            progressItems[uuid]
        }
    }

    public func hasProgressForUserEpisode(_ uuid: String) -> Bool {
        progressItemsQueue.sync {
            progressItems[uuid] != nil
        }
    }

    public func countOfUploadingItems() -> Int {
        progressItemsQueue.sync {
            progressItems.count
        }
    }

    public func updateProgressForEpisode(_ uuid: String, totalBytesSent: Int64, totalBytesExpected: Int64) {
        progressItemsQueue.sync {
            var progressItem = progressItems[uuid]
            if progressItem == nil {
                progressItem = UploadProgress()
                finishedItemCount = 0
            }

            progressItem?.totalToUpload = totalBytesExpected
            progressItem?.uploadedSoFar = totalBytesSent
            progressItems[uuid] = progressItem!
        }

        // throttle updates to once every 1s so we don't flood the UI thread
        if lastUiUpdateTime == nil || lastUiUpdateTime!.timeIntervalSinceNow < -1 {
            NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadProgress, object: nil)
            lastUiUpdateTime = Date()
        }
    }

    public func updateStatusForEpisode(_ uuid: String, status: UploadStatus) {
        progressItemsQueue.sync {
            var progressItem = progressItems[uuid]
            if progressItem == nil {
                progressItem = UploadProgress()
                finishedItemCount = 0
            }

            progressItem?.status = status
            progressItems[uuid] = progressItem!
        }
    }

    public func removeProgressForEpisode(_ uuid: String) {
        progressItemsQueue.sync {
            finishedItemCount += 1
            progressItems.removeValue(forKey: uuid)
        }
    }
}
