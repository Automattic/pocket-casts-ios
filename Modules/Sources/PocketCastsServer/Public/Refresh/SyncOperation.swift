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

            // Up Next syncs share a queue, so this one doesn't overlap one started by an Up Next change
            var upNextTasks: [ApiBaseTask] = [UpNextSyncTask()]
            if SubscriptionHelper.hasActiveSubscription() { upNextTasks.insert(RetrieveCustomFilesTask(), at: 0) }
            upNextTasks.forEach { $0.logsDuration = true }
            upNextTasksLock.withLock { self.upNextTasks = upNextTasks }
            RefreshManager.shared.upNextQueue.addOperations(upNextTasks, waitUntilFinished: true)

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

    private var upNextTasks = [ApiBaseTask]()
    private let upNextTasksLock = NSLock()

    override func cancel() {
        super.cancel()
        upNextTasksLock.withLock { upNextTasks }.forEach { $0.cancel() }
        apiQueue.cancelAllOperations()
    }

    private func addTimedOperation(_ task: ApiBaseTask) {
        task.logsDuration = true
        apiQueue.addOperation(task)
    }
}
