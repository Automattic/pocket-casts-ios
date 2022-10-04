import DataModel
import Foundation
import SwiftProtobuf
import Utils

class RetrieveCustomFilesTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "files"

        do {
            var headers: [String: String]?
            if let lastModified = Settings.filesLastModified() {
                headers = [Server.HttpHeaders.ifModifiedSince: lastModified]
            }
            let (data, httpResponse) = getToServer(url: url, token: token, customHeaders: headers)

            if httpResponse?.statusCode == Server.HttpConstants.notModified {
                FileLog.shared.addMessage("RetrieveCustomFilesTask - not modified, no changes required")
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodesRefreshed)
                return
            }

            guard let responseData = data, httpResponse?.statusCode == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("RetrieveCustomFilesTask - server returned \(httpResponse?.statusCode ?? -1), firing refresh failed")
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodesRefreshFailed)

                return
            }

            do {
                let serverResponse = try Files_FileListResponse(serializedData: responseData)

                Settings.setCustomStorageUserLimit(Int(serverResponse.account.totalSize))
                Settings.setCustomStorageUsed(Int(serverResponse.account.usedSize))
                Settings.setCustomStorageNumFiles(Int(serverResponse.account.totalFiles))
                FileLog.shared.addMessage("Total user files  \(serverResponse.account.totalFiles), total size \(serverResponse.account.totalSize) used size \(serverResponse.account.usedSize)")

                var episodes = [UserEpisode]()
                for serverEpisode in serverResponse.files {
                    let convertedEpisode = convertFromProto(serverEpisode)
                    episodes.append(convertedEpisode)
                }

                processServerEpisodes(episodes: episodes)

                // save last modified time for the next time we make this call
                if let lastModified = httpResponse?.allHeaderFields[Server.HttpHeaders.lastModified] as? String {
                    Settings.setFilesLastModified(lastModified)
                }
            } catch {
                FileLog.shared.addMessage("Decoding User episodes failed \(error.localizedDescription)")
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodesRefreshFailed)
            }
        }
    }

    private func processServerEpisodes(episodes: [UserEpisode]) {
        // the code below isn't thread safe, because it queries the database then does a save with potentially old user episode info (potentially causing an INSERT where an UPDATE is required instead)
        // to work around this we lock it so that this method can only be run by one thread at once
        let lock = UploadManager.shared
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }

        let uploadedEpisodes = DataManager.sharedManager.allUserEpisodesUploaded()
        let deletedEpisodes = uploadedEpisodes.filter { uploaded in
            !episodes.contains(where: { $0.uuid == uploaded.uuid })
        }

        for deleted in deletedEpisodes {
            DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, episode: deleted)
            UserEpisodeManager.deleteFromDevice(userEpisode: deleted)
        }

        var autodownloadEpisodes = [UserEpisode]()
        for episode in episodes {
            if let localEpisode = DataManager.sharedManager.findUserEpisode(uuid: episode.uuid) {
                episode.id = localEpisode.id
                episode.addedDate = localEpisode.addedDate
                episode.publishedDate = localEpisode.publishedDate
                episode.uploadStatus = UploadStatus.uploaded.rawValue
                episode.episodeStatus = localEpisode.episodeStatus
                episode.autoDownloadStatus = localEpisode.autoDownloadStatus
                if localEpisode.imageModified > 0 { // don't override an image change that hasn't uploaded
                    episode.imageUrl = localEpisode.imageUrl
                }
                if localEpisode.imageColorModified > 0 {
                    episode.imageColor = localEpisode.imageColor
                }
                if localEpisode.titleModified > 0 {
                    episode.title = localEpisode.title
                }
            } else {
                if episode.publishedDate == nil { episode.publishedDate = Date() }
                episode.addedDate = episode.publishedDate
                episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
                episode.uploadStatus = UploadStatus.uploaded.rawValue
                if Settings.userEpisodeAutoDownload() {
                    autodownloadEpisodes.append(episode)
                }
            }
        }

        DataManager.sharedManager.bulkSave(episodes: episodes)

        let autoDownloadsRequireWifi = Settings.userEpisodeOnlyOnWifi()
        let isWiFiConnected = NetworkUtils.shared.isConnectedToWifi()
        for episode in autodownloadEpisodes {
            if isWiFiConnected || !autoDownloadsRequireWifi {
                DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            } else {
                DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            }
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodesRefreshed)
    }

    private func convertFromProto(_ protoEpisode: Files_File) -> UserEpisode {
        let episode = UserEpisode()
        episode.uuid = protoEpisode.uuid
        episode.title = protoEpisode.title
        episode.fileType = protoEpisode.contentType
        episode.sizeInBytes = protoEpisode.size
        episode.duration = Double(protoEpisode.duration)
        episode.playedUpTo = Double(protoEpisode.playedUpTo)
        episode.playingStatus = Int32(protoEpisode.playingStatus)
        episode.imageUrl = protoEpisode.imageURL
        episode.imageColor = protoEpisode.colour

        return episode
    }
}
