import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveCustomFilesTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files"

        do {
            var headers: [String: String]?
            if let lastModified = ServerSettings.filesLastModified() {
                headers = [ServerConstants.HttpHeaders.ifModifiedSince: lastModified]
            }
            let (data, httpResponse) = getToServer(url: url, token: token, customHeaders: headers)

            if httpResponse?.statusCode == ServerConstants.HttpConstants.notModified {
                FileLog.shared.addMessage("RetrieveCustomFilesTask - not modified, no changes required")
                NotificationCenter.default.post(name: ServerNotifications.userEpisodesRefreshed, object: nil)
                return
            }

            guard let responseData = data, httpResponse?.statusCode == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("RetrieveCustomFilesTask - server returned \(httpResponse?.statusCode ?? -1), firing refresh failed")
                NotificationCenter.default.post(name: ServerNotifications.userEpisodesRefreshFailed, object: nil)

                return
            }

            do {
                let serverResponse = try Files_FileListResponse(serializedData: responseData)
                #if !os(watchOS) // WatchOS doesn't handle the 10GB user File limits
                    ServerSettings.setCustomStorageUserLimit(Int(serverResponse.account.totalSize))
                    ServerSettings.setCustomStorageUsed(Int(serverResponse.account.usedSize))
                #endif
                ServerSettings.setCustomStorageNumFiles(Int(serverResponse.account.totalFiles))
                FileLog.shared.addMessage("Total user files  \(serverResponse.account.totalFiles), total size \(serverResponse.account.totalSize) used size \(serverResponse.account.usedSize)")

                var episodes = [UserEpisode]()
                for serverEpisode in serverResponse.files {
                    let convertedEpisode = convertFromProto(serverEpisode)
                    episodes.append(convertedEpisode)
                }

                processServerEpisodes(episodes: episodes)

                // save last modified time for the next time we make this call
                if let lastModified = httpResponse?.allHeaderFields[ServerConstants.HttpHeaders.lastModified] as? String {
                    ServerSettings.setFilesLastModified(lastModified)
                }
            } catch {
                FileLog.shared.addMessage("Decoding User episodes failed \(error.localizedDescription)")
                NotificationCenter.default.post(name: ServerNotifications.userEpisodesRefreshFailed, object: nil)
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

        for deletedEpisode in deletedEpisodes {
            DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, episode: deletedEpisode)
            if let fileProtocol = ServerConfig.shared.syncDelegate?.userEpisodeFileProtocol(), !deletedEpisode.downloaded(pathFinder: fileProtocol) {
                ServerConfig.shared.syncDelegate?.deleteFromDevice(userEpisode: deletedEpisode)
            }
        }

        var autodownloadEpisodes = [UserEpisode]()
        var updatedNowPlayingTime: TimeInterval = -1
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

                // if the episode is loaded into the player, and is currently paused record the up to time so we can seek there
                if let playbackDelegate = ServerConfig.shared.playbackDelegate, playbackDelegate.isNowPlayingEpisode(episodeUuid: episode.uuid), !playbackDelegate.playing() {
                    updatedNowPlayingTime = episode.playedUpTo
                }
            } else {
                if episode.publishedDate == nil { episode.publishedDate = Date() }
                episode.addedDate = episode.publishedDate
                episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
                episode.uploadStatus = UploadStatus.uploaded.rawValue
                if ServerSettings.userEpisodeAutoDownload() {
                    autodownloadEpisodes.append(episode)
                }
            }
        }

        DataManager.sharedManager.bulkSave(episodes: episodes)

        // if the currently playing episode was modified, make sure we seek to the correct time for it
        if let playbackDelegate = ServerConfig.shared.playbackDelegate, updatedNowPlayingTime >= 0 {
            playbackDelegate.seekToFromSync(time: updatedNowPlayingTime, syncChanges: false, startPlaybackAfterSeek: false)
        }

        if autodownloadEpisodes.count > 0 {
            ServerConfig.shared.syncDelegate?.autoDownloadUserEpisodes(episodes: autodownloadEpisodes)
        }

        NotificationCenter.default.post(name: ServerNotifications.userEpisodesRefreshed, object: nil)
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
