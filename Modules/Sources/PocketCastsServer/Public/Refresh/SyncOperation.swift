import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/// Syncs Up Next, episodes, history and settings with the server.
class SyncOperation: Operation, @unchecked Sendable {
    private(set) var status = UpdateStatus.notStarted

    /// Whether the sync ran and didn't fail.
    private(set) var succeeded = false

    private lazy var apiQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    override func main() {
        autoreleasepool {
            if isCancelled {
                status = .cancelled
                return
            }

            NotificationCenter.default.post(name: ServerNotifications.syncStarted, object: nil)
            let startDate = Date()

            if SubscriptionHelper.hasActiveSubscription() { addTimedOperation(RetrieveCustomFilesTask()) }
            addTimedOperation(UpNextSyncTask())
            let syncTask = SyncTask()
            addTimedOperation(syncTask)

            addTimedOperation(SyncHistoryTask())

            addTimedOperation(SyncSettingsTask())

            #if !os(watchOS)
                ServerSettings.iapUnverifiedPurchaseReceiptDate() == nil ? addTimedOperation(SubscriptionStatusTask()) : addTimedOperation(PurchaseReceiptTask())
            #endif

            #if !os(watchOS)
                // update our local copy of the remote stats. Doesn't really matter if this fails or succeeds
                StatsManager.shared.loadRemoteStats(completion: nil)
            #endif

            apiQueue.waitUntilAllOperationsAreFinished()

            // we use the sync task as the main indication of whether the sync has failed
            status = isCancelled ? .cancelled : syncTask.status
            if status == .failed || status == .cancelled {
                FileLog.shared.addMessage("Sync failed in \(startDate.elapsedTimeDescription)")
            } else {
                succeeded = true
                FileLog.shared.addMessage("Sync succeeded in \(startDate.elapsedTimeDescription)")

                ServerNotificationsHelper.shared.fireSyncCompleted()
                ServerConfig.shared.syncDelegate?.playlistChanged()
            }
        }
    }

    override func cancel() {
        super.cancel()
        apiQueue.cancelAllOperations()
    }

    private func addTimedOperation(_ task: ApiBaseTask) {
        task.logsDuration = true
        apiQueue.addOperation(task)
    }
}
