import Foundation
import PocketCastsDataModel
import PocketCastsUtils
#if os(watchOS)
    import WatchKit
#endif

extension DownloadManager {
    #if os(watchOS)
        func processBackgroundTaskCallback(task: WKURLSessionRefreshBackgroundTask) {
            if task.sessionIdentifier == DownloadManager.cellBackgroundSessionId {
                pendingWatchBackgroundTask = task
            } else {
                task.setTaskCompletedWithSnapshot(true)
            }
        }
    #endif

    func transferForegroundDownloadsToBackground() {
        cellularForegroundSession.getTasksWithCompletionHandler { _, _, downloadTasks in
            for foregroundTask in downloadTasks {
                guard let request = foregroundTask.currentRequest else { continue }

                // clear the task description here so that when we cancel it we don't update the episode associated with it, since we're about to resume it straight after
                let savedTaskDescription = foregroundTask.taskDescription
                foregroundTask.taskDescription = nil

                // cancel the foreground task, and transfer it to the background. Try to use the resume data if some is returned so it doesn't have to start again
                foregroundTask.cancel { data in
                    let backgroundTask: URLSessionDownloadTask
                    if let data = data {
                        backgroundTask = self.cellularBackgroundSession.downloadTask(withResumeData: data)
                    } else {
                        backgroundTask = self.cellularBackgroundSession.downloadTask(with: request)
                    }
                    backgroundTask.taskDescription = savedTaskDescription
                    backgroundTask.resume()
                }
            }
        }
    }

    func clearStuckDownloads() {
        let episodesWithDownloadIds = DataManager.sharedManager.findEpisodesWhereNotNull(propertyName: "downloadTaskId")
        if episodesWithDownloadIds.count == 0 { return }

        var episodeUuids = [String]()
        for episode in episodesWithDownloadIds {
            episodeUuids.append(episode.uuid)
        }

        wifiOnlyBackgroundSession.getTasksWithCompletionHandler { [weak self] _, _, downloadTasks in
            guard let strongSelf = self else { return }
            for task in downloadTasks {
                if let taskId = task.taskDescription, let episode = DataManager.sharedManager.findBaseEpisode(downloadTaskId: taskId), let index = episodeUuids.firstIndex(of: episode.uuid) {
                    episodeUuids.remove(at: index)
                }
            }

            strongSelf.cellularBackgroundSession.getTasksWithCompletionHandler { _, _, downloadTasks in
                for task in downloadTasks {
                    if let taskId = task.taskDescription, let episode = DataManager.sharedManager.findBaseEpisode(downloadTaskId: taskId), let index = episodeUuids.firstIndex(of: episode.uuid) {
                        episodeUuids.remove(at: index)
                    }
                }

                if episodeUuids.count == 0 { return }

                for episodeUuid in episodeUuids {
                    guard let episode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else { continue }

                    let downloadStatus: DownloadStatus = episode.downloaded(pathFinder: strongSelf) ? .downloaded : .notDownloaded
                    DataManager.sharedManager.saveEpisode(downloadStatus: downloadStatus, downloadTaskId: nil, episode: episode)
                    FileLog.shared.addMessage("Clearing download status on an episode that isn't downloading anymore: \(episode.displayableTitle())")
                }
            }
        }
    }
}
