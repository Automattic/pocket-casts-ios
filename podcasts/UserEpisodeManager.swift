import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

struct UserEpisodeManager {
    #if !os(watchOS)
        static func addUserEpisode(uuid: String, title: String, localFileUrl: URL, artwork: UIImage?, color: Int, fileSize: Int, duration: TimeInterval) throws -> UserEpisode {
            let episode = UserEpisode()
            episode.title = title
            episode.addedDate = Date()
            episode.publishedDate = Date()
            episode.fileType = FileTypeUtil.typeForFileExtension(forExtension: localFileUrl.absoluteString)
            episode.duration = duration
            episode.uuid = uuid
            episode.sizeInBytes = Int64(fileSize)
            episode.episodeStatus = DownloadStatus.downloaded.rawValue
            if let artwork = artwork {
                episode.imageColor = 0
                do {
                    let filePath = episode.urlForImage()
                    try artwork.jpegData(compressionQuality: 1)?.write(to: filePath)
                    episode.hasCustomImage = true
                } catch {
                    throw error
                }
            } else {
                episode.imageColor = Int32(color)
                episode.hasCustomImage = false
            }

            DataManager.sharedManager.save(episode: episode)

            if SubscriptionHelper.hasActiveSubscription(), Settings.userFilesAutoUpload() {
                uploadUserEpisode(userEpisode: episode)
            }

            if Settings.userEpisodeAutoAddToUpNext() {
                PlaybackManager.shared.addToUpNext(episode: episode, userInitiated: false)
            }

            return episode
        }
    #endif

    static func renameUserEpisode(title: String, userEpisode: UserEpisode) {
        userEpisode.title = title
        DataManager.sharedManager.save(episode: userEpisode)
    }

    static func uploadUserEpisode(userEpisode: UserEpisode) {
        if ServerSettings.userEpisodeOnlyOnWifi(), !NetworkUtils.shared.isConnectedToUnexpensiveConnection() {
            UploadManager.shared.queueForLaterUpload(episodeUuid: userEpisode.uuid, fireNotification: true)
        } else {
            UploadManager.shared.addToQueue(episodeUuid: userEpisode.uuid)
        }
    }

    static func updateUserEpisodes() {
        let episodes = DataManager.sharedManager.unsyncedUserEpisodes()
        if episodes.count > 0 {
            ApiServerHandler.shared.uploadFilesUpdateRequest(episodes: episodes, completion: { _ in })
        }

        ApiServerHandler.shared.retrieveCustomFilesTask()
    }

    // MARK: Delete

    static func deleteFromCloud(episode: UserEpisode, removeFromPlaybackQueue: Bool = true) {
        if !episode.uploaded() { return }

        guard episode.downloaded(pathFinder: DownloadManager.shared) else {
            deleteFromEverywhere(userEpisode: episode, removeFromPlaybackQueue: removeFromPlaybackQueue)
            return
        }

        DataManager.sharedManager.saveEpisode(uploadStatus: .deleteFromCloudPending, episode: episode)
        NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadStatusChanged, object: episode.uuid)

        ApiServerHandler.shared.uploadFileDelete(episode: episode, completion: { success in
            guard let success = success, success else { return }
            DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, episode: episode)
            NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadStatusChanged, object: episode.uuid)
            UserEpisodeManager.updateUserEpisodes()
        })

        #if !os(watchOS)
            AnalyticsEpisodeHelper.shared.episodeDeletedFromCloud(episode: episode)
        #endif
    }

    static func deleteFromDevice(userEpisode: UserEpisode, removeFromPlaybackQueue: Bool = true) {
        DownloadManager.shared.removeFromQueue(episodeUuid: userEpisode.uuid, fireNotification: false, userInitiated: true)
        if removeFromPlaybackQueue {
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: userEpisode, fireNotification: true)
        }
        EpisodeManager.deleteDownloadedFiles(episode: userEpisode)

        // if this file isn't uploaded, then it can't be redownloaded, so blow it away
        if !userEpisode.uploaded() {
            DataManager.sharedManager.delete(userEpisodeUuid: userEpisode.uuid)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodeDeleted, object: userEpisode.uuid)
        } else {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: userEpisode.uuid)
        }
    }

    static func deleteFromEverywhere(userEpisode: UserEpisode, removeFromPlaybackQueue: Bool = true) {
        DataManager.sharedManager.saveEpisode(uploadStatus: .deleteFromCloudAndLocalPending, episode: userEpisode)
        NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadStatusChanged, object: userEpisode.uuid)

        if removeFromPlaybackQueue {
            PlaybackManager.shared.removeIfPlayingOrQueued(episode: userEpisode, fireNotification: true)
        }

        ApiServerHandler.shared.uploadFileDelete(episode: userEpisode, completion: { success in
            guard let success = success else { return }
            if success {
                DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, episode: userEpisode)
                UserEpisodeManager.deleteFromDevice(userEpisode: userEpisode, removeFromPlaybackQueue: false)
                UserEpisodeManager.updateUserEpisodes()
            }
        })
    }

    static func checkForPendingCloudDeletes() {
        let allCloudDeletes = DataManager.sharedManager.findUserEpisodesWithUploadStatus(.deleteFromCloudPending)
        if allCloudDeletes.count > 0 {
            ApiServerHandler.shared.processPendingCloudDeletes(episodes: allCloudDeletes, deleteCompletedHandler: nil)
        }

        let allLocalAndCloudDeletes = DataManager.sharedManager.findUserEpisodesWithUploadStatus(.deleteFromCloudAndLocalPending)
        if allLocalAndCloudDeletes.count > 0 {
            ApiServerHandler.shared.processPendingCloudDeletes(episodes: allLocalAndCloudDeletes) { episode in
                UserEpisodeManager.deleteFromDevice(userEpisode: episode, removeFromPlaybackQueue: false)
            }
        }
    }

    static func checkForPendingUploads() {
        // check if any existing episode that have been queued need to be uploaded
        if NetworkUtils.shared.isConnectedToUnexpensiveConnection() {
            let queuedEpisodes = DataManager.sharedManager.findUserEpisodesWithUploadStatus(.waitingForWifi)
            for episode in queuedEpisodes {
                UploadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: true)
            }
        }
    }

    static func removeOrphanedUserEpisodes() {
        DataManager.sharedManager.removeOrphanedUserEpisodes()
    }

    // MARK: - Update User Episode

    static func updateUserEpisode(uuid: String, title: String, color: Int) {
        guard let episode = DataManager.sharedManager.findUserEpisode(uuid: uuid) else {
            return
        }
        var episodeSyncRequired = false
        if episode.title != title {
            episode.title = title
            episode.titleModified = TimeFormatter.currentUTCTimeInMillis()
            episodeSyncRequired = true
        }
        if episode.imageColor != Int32(color) || episode.imageColorModified > 0 {
            episode.imageColor = Int32(color)
            episode.imageColorModified = TimeFormatter.currentUTCTimeInMillis()
            episodeSyncRequired = true
        }

        DataManager.sharedManager.save(episode: episode)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodeUpdated, object: episode.uuid)
        if episodeSyncRequired {
            ApiServerHandler.shared.uploadSingleFileUpdateRequest(episode: episode, completion: { response in
                FileLog.shared.addMessage("User file update response \(response)")
            })
        }
    }

    #if !os(watchOS)
        static func updateUserEpisodeImage(uuid: String, artwork: UIImage?, completion: @escaping () -> Void) throws {
            guard let episode = DataManager.sharedManager.findUserEpisode(uuid: uuid) else {
                return
            }

            do {
                let imageUrl = episode.urlForImage()
                if imageUrl.isFileURL, FileManager.default.fileExists(atPath: imageUrl.absoluteString) { // remove Local artwork
                    try FileManager.default.removeItem(at: imageUrl)
                }

                ImageManager.sharedManager.removeUserEpisodeImage(episode: episode, completionHandler: {
                    episode.imageUrl = nil
                    if episode.imageColor != 0 {
                        episode.imageColor = 0
                        episode.imageColorModified = TimeFormatter.currentUTCTimeInMillis()
                    }

                    let filePath = episode.urlForImage()
                    if let artwork = artwork {
                        do {
                            try artwork.jpegData(compressionQuality: 1)?.write(to: filePath)
                            episode.imageModified = TimeFormatter.currentUTCTimeInMillis()
                        } catch {
                            //   throw error
                            print("failed to save artowrk")
                        }
                        episode.hasCustomImage = true
                    }
                    DataManager.sharedManager.save(episode: episode)
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodeUpdated, object: episode.uuid)
                    if episode.uploaded() {
                        if artwork != nil {
                            UploadManager.shared.uploadImageFor(episode: episode, session: nil)
                        } else {
                            ApiServerHandler.shared.uploadImageDelete(episode: episode, completion: { success in
                                print("Server image delete result \(String(describing: success))")
                                // TODO: handle failure to remove image
                            })
                        }
                    }
                    completion()
                })
            } catch {
                throw error
            }
        }
    #endif

    static func cleanupCloudOnlyFiles() {
        UploadManager.shared.stopAllUploads()

        let cloudEpisodes = DataManager.sharedManager.allUserEpisodesUploaded()
        for episode in cloudEpisodes {
            if episode.downloaded(pathFinder: DownloadManager.shared) {
                if episode.uploaded() || episode.uploadFailed() {
                    DataManager.sharedManager.saveEpisode(uploadStatus: .notUploaded, episode: episode)
                }
            } else {
                DownloadManager.shared.removeFromQueue(episodeUuid: episode.uuid, fireNotification: false, userInitiated: true)
                PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true)
                DataManager.sharedManager.delete(userEpisodeUuid: episode.uuid)
            }
        }
        ServerSettings.removeFilesLastModifiedKey()
    }

    #if !os(watchOS)
    static func presentDeleteOptions(episode: UserEpisode, preferredStatusBarStyle: UIStatusBarStyle, themeOverride: Theme.ThemeType?, dismissCallback: (() -> ())? = nil, actionCallback: ((Bool, Bool) -> Void)? = nil) {
            let optionPicker = OptionsPicker(title: "", themeOverride: themeOverride)

            if let dismissCallback {
                optionPicker.setNoActionCallback(dismissCallback)
            }

            let deleteCloudAction = OptionAction(label: L10n.deleteFromCloud, icon: nil, action: { [] in
                UserEpisodeManager.deleteFromCloud(episode: episode)
                actionCallback?(false, true)
            })

            let deleteDeviceLabel = episode.uploaded() && episode.downloaded(pathFinder: DownloadManager.shared) ? L10n.deleteFromDeviceOnly : L10n.deleteFromDevice
            let deleteDeviceAction = OptionAction(label: deleteDeviceLabel, icon: nil, action: { [] in
                UserEpisodeManager.deleteFromDevice(userEpisode: episode)
                actionCallback?(true, false)
            })
            let deleteEverywhereAction = OptionAction(label: L10n.deleteEverywhereShort, icon: nil, action: { [] in
                UserEpisodeManager.deleteFromEverywhere(userEpisode: episode)
                actionCallback?(true, true)
            })
            deleteDeviceAction.destructive = episode.uploaded() && episode.downloaded(pathFinder: DownloadManager.shared) ? false : true
            deleteCloudAction.destructive = true
            deleteEverywhereAction.destructive = true

            var actions: [OptionAction]
            if episode.downloaded(pathFinder: DownloadManager.shared), episode.uploaded() {
                actions = [deleteDeviceAction, deleteEverywhereAction]
            } else if episode.downloaded(pathFinder: DownloadManager.shared), !episode.uploaded() {
                actions = [deleteDeviceAction]
            } else if !episode.downloaded(pathFinder: DownloadManager.shared), episode.uploaded() {
                actions = [deleteCloudAction]
            } else {
                actions = [deleteDeviceAction]
            }

            let title: String
            if episode.uploaded(), !episode.downloaded(pathFinder: DownloadManager.shared) {
                title = L10n.deleteFromCloud
            } else if !episode.uploaded(), episode.downloaded(pathFinder: DownloadManager.shared) {
                title = L10n.deleteFromDevice
            } else {
                title = L10n.deleteFile
            }
            optionPicker.addDescriptiveActions(title: title, message: L10n.deleteFileMessage, icon: "delete-red", actions: actions)

            optionPicker.show(statusBarStyle: preferredStatusBarStyle)
        }
    #endif
}
