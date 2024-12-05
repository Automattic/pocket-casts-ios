import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension BackgroundSyncManager: URLSessionDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // one of our 3 tasks has finished, but since they can come back in any order we need to decide whether to process this now, or when another one return
        // we also extract the data here, because it will be deleted when this method exits, and some of the things we call run on another thread
        var data: Data?
        do {
            data = try Data(contentsOf: location)
        } catch {
            FileLog.shared.addMessage("Failed to load background sync data: \(error.localizedDescription)")
        }

        if downloadTask.taskDescription == refreshTaskId {
            processRefreshResponse(data: data)
            haveProcessedRefresh = true
            processPendingData()
        } else if downloadTask.taskDescription == upNextSyncTaskId {
            if haveProcessedRefresh {
                processUpNextSyncData(data)
                processPendingData()
            } else {
                pendingUpNextSyncData = data
            }
        } else if downloadTask.taskDescription == syncTaskId {
            if haveProcessedRefresh {
                processSyncResponse(data: data, task: downloadTask)
                processPendingData()
            } else {
                pendingSyncData = data
                pendingSyncHttpCode = downloadTask.response?.extractStatusCode()
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            FileLog.shared.addMessage("URLSession didCompleteWithError \(error.localizedDescription)")
            return
        }

        FileLog.shared.addMessage("URLSession download finished, status code: \(task.response?.extractStatusCode() ?? 0), task \(task.taskDescription ?? "no description")")
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        FileLog.shared.addMessage("BackgroundSyncManager urlSessionDidFinishEvents called, queing completion")
        syncProcessQueue.addOperation {
            FileLog.shared.addMessage("Processing queue complete, firing sync completed and completing task")
            ServerNotificationsHelper.shared.fireSyncCompleted()
            #if os(watchOS)
            if  let identifier = session.configuration.identifier, let pendingWatchBackgroundTask = self.pendingWatchBackgroundTasks[identifier] {
                pendingWatchBackgroundTask.setTaskCompletedWithSnapshot(true)
                self.pendingWatchBackgroundTasks[identifier] = nil
            }
            #endif

            session.invalidateAndCancel()
            self.pendingTasks.removeAll()
        }
    }

    // MARK: - Private Processing Helpers

    private func processPendingData() {
        if let pendingSync = pendingSyncData, let httpCode = pendingSyncHttpCode {
            processSyncData(pendingSync, httpCode: httpCode)
            pendingSyncData = nil
            pendingSyncHttpCode = nil
        }

        if let pendingUpNextSync = pendingUpNextSyncData {
            processUpNextSyncData(pendingUpNextSync)
            pendingUpNextSyncData = nil
        }
    }

    // MARK: - Up Next Processing

    private func processUpNextSyncData(_ data: Data?) {
        guard let data = data else { return }

        syncProcessQueue.addOperation {
            let upNextTask = UpNextSyncTask()

            upNextTask.process(serverData: data, latestActionTime: self.lastUpNextActionTime)
            self.lastUpNextActionTime = 0
        }
    }

    // MARK: - Sync Processing

    private func processSyncResponse(data: Data?, task: URLSessionDownloadTask) {
        if let httpCode = task.response?.extractStatusCode() {
            processSyncData(data, httpCode: httpCode)
        } else {
            FileLog.shared.addMessage("Background Sync failed to find http status code")
        }
    }

    private func processSyncData(_ data: Data?, httpCode: Int) {
        syncProcessQueue.addOperation {
            let syncTask = SyncTask()
            // this is slightly problematic because this might not return the list that was originally synced, but also we can't store that in memory because the app can be killed between start and finish
            // if this turns out to be an issue we could perhaps persist the UUIDs to UserDefaults, or come up with some other solution to this
            let episodesSynced: [Episode]
            if FeatureFlag.useSyncResponseEpisodeIDs.enabled {
                episodesSynced = DataManager.sharedManager.unsyncedEpisodes(limit: ServerConstants.Limits.maxEpisodesToSync)
            } else {
                episodesSynced = []
            }
            _ = syncTask.processSyncData(data, httpStatus: httpCode, episodesToSync: episodesSynced)
        }
    }

    // MARK: - Refresh Processing

    private func processRefreshResponse(data: Data?) {
        guard let data = data else { return }

        syncProcessQueue.addOperation {
            let response = ServerHelper.decodeRefreshResponse(from: data)
            if response.success(), let result = response.result {
                let refreshOperation = RefreshOperation(result: result, completionHandler: nil)
                let status = refreshOperation.performRefresh()
                if status == .cancelled || status == .failed {
                    FileLog.shared.addMessage("Background refresh failed processing data")
                }
            } else {
                FileLog.shared.addMessage("Background refresh server call failed")
            }
        }
    }
}
