import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension UploadManager: URLSessionDelegate, URLSessionDataDelegate {
    // things smaller than 10kbs are not episodes, way too small and something has gone wrong
    private static let badEpisodeSize = 10 * 1024

    // things smaller than 150kb are suspect, probably text, xml or html error pages
    private static let suspectEpisodeSize = 150 * 1024

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // make sure we call the completion handler on the main queue, otherwise it will crash
        DispatchQueue.main.async {
            guard let backgroundHandler = ServerConfig.shared.backgroundSessionCompletionHandler() else { return }

            ServerConfig.shared.setBackgroundSessionCompletionHandler(handler: nil)
            backgroundHandler()
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? URLSessionUploadTask, let taskId = task.taskDescription, let episode = episodeForTask(task, forceReload: true, includeImageTasks: true) else {
            // if there's no error then no need for us to do anything
            return
        }

        removeTaskIdFromCache(taskId: taskId)

        if isImageUpload(taskId: taskId) {
            if let error = error as NSError? {
                FileLog.shared.addMessage("Upload Manager failed to upload image \(error.localizedDescription)")
            } else {
                DataManager.sharedManager.markImageUploaded(episode: episode)
            }
        } else {
            if let error = error as NSError? {
                if error.code == NSURLErrorCancelled {
                    if !episode.uploadFailed() {
                        return
                    } else {
                        DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, uploadTaskId: nil, episode: episode)
                    }
                }

                DataManager.sharedManager.saveEpisode(uploadStatus: .uploadFailed, uploadError: error.localizedDescription, uploadTaskId: nil, episode: episode)
                NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadStatusChanged, object: episode.uuid)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ApiServerHandler.shared.uploadFilesUpdateStatusRequest(episode: episode)
                }
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let uploadTask = task as? URLSessionUploadTask,
              let taskId = task.taskDescription,
              !isImageUpload(taskId: taskId),
              let uploadingEpisode = episodeForTask(uploadTask, forceReload: false) else { return }

        progressManager.updateProgressForEpisode(uploadingEpisode.uuid, totalBytesSent: totalBytesSent, totalBytesExpected: totalBytesExpectedToSend)
    }

    private func episodeForTask(_ task: URLSessionUploadTask, forceReload: Bool, includeImageTasks: Bool = false) -> UserEpisode? { // TODO: allow image upload
        guard let uploadId = task.taskDescription else { return nil }

        if !forceReload {
            if let episode = uploadingEpisodesCache[uploadId] {
                return episode
            }
        }

        var episode = DataManager.sharedManager.findUserEpisode(uploadTaskId: uploadId)
        if let episode = episode {
            uploadingEpisodesCache[uploadId] = episode
        } else {
            if includeImageTasks {
                let imageUuid = uploadId.replacingOccurrences(of: imageTaskPrefix, with: "")

                let imageEpisode = DataManager.sharedManager.findUserEpisode(uuid: imageUuid)
                if let imageEpisode = imageEpisode {
                    episode = imageEpisode
                    uploadingEpisodesCache[uploadId] = episode
                }
            }
        }

        return episode
    }
}
