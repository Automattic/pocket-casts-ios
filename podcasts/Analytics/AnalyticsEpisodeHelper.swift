import Foundation
import PocketCastsDataModel
import PocketCastsServer

class AnalyticsEpisodeHelper {
    static var shared = AnalyticsEpisodeHelper()
    
    /// Sometimes the playback source can't be inferred, just inform it here
    var currentSource: String?

    // Internally track the episode UUIDs that the user is downloading or uploadiung
    private var episodeDownloadQueue: Set<String> = []
    private var episodeUploadQueue: Set<String> = []

    init() {
        addNotificationObservers()
    }

    #if !os(watchOS)

        // MARK: - Star

        func star(episode: BaseEpisode) {
            episodeEvent(.episodeStarred, episode: episode)
        }

        func bulkStar(count: Int) {
            bulkEvent(.episodeBulkStarred, count: count)
        }

        func unstar(episode: BaseEpisode) {
            episodeEvent(.episodeUnstarred, episode: episode)
        }

        func bulkUnstar(count: Int) {
            bulkEvent(.episodeBulkUnstarred, count: count)
        }

        // MARK: - Download

        func downloadCancelled(episodeUUID: String) {
            episodeEvent(.episodeDownloadCancelled, uuid: episodeUUID)
        }

        func downloaded(episodeUUID: String) {
            episodeDownloadQueue.insert(episodeUUID)
            episodeEvent(.episodeDownloadQueued, uuid: episodeUUID)
        }

        func downloadFinished(episodeUUID: String) {
            episodeEvent(.episodeDownloadFinished, uuid: episodeUUID)
        }

        func bulkDownloadEpisodes(episodes: [BaseEpisode]) {
            let uuids = episodes.map { $0.uuid }
            episodeDownloadQueue.formUnion(uuids)
            bulkEvent(.episodeBulkDownloadQueued, count: episodes.count)
        }
    
        func downloadDeleted(episode: BaseEpisode) {
            episodeEvent(.episodeDownloadDeleted, episode: episode)
        }

        func bulkDeleteDownloadedEpisodes(count: Int) {
            bulkEvent(.episodeBulkDownloadDeleted, count: count)
        }

        // MARK: - Played

        func markAsPlayed(episode: BaseEpisode) {
            episodeEvent(.episodeMarkedAsPlayed, episode: episode)
        }

        func bulkMarkAsPlayed(count: Int) {
            bulkEvent(.episodeBulkMarkedAsPlayed, count: count)
        }

        func markAsUnplayed(episode: BaseEpisode) {
            episodeEvent(.episodeMarkedAsUnplayed, episode: episode)
        }

        func bulkMarkAsUnplayed(count: Int) {
            bulkEvent(.episodeBulkMarkedAsUnplayed, count: count)
        }

        // MARK: - Archive

        func archiveEpisode(_ episode: BaseEpisode) {
            episodeEvent(.episodeArchived, episode: episode)
        }

        func bulkArchiveEpisodes(count: Int) {
            bulkEvent(.episodeBulkArchived, count: count)
        }

        func unarchiveEpisode(_ episode: BaseEpisode) {
            episodeEvent(.episodeUnarchived, episode: episode)
        }

        func bulkUnarchiveEpisodes(count: Int) {
            bulkEvent(.episodeBulkUnarchived, count: count)
        }

        // MARK: - Uploads

        func episodeUploaded(episodeUUID: String) {
            episodeUploadQueue.insert(episodeUUID)
            episodeEvent(.episodeUploadQueued, uuid: episodeUUID)
        }

        func episodeUploadCancelled(episodeUUID: String) {
            episodeEvent(.episodeUploadCancelled, uuid: episodeUUID)
        }

        func episodeDeletedFromCloud(episode: BaseEpisode) {
            episodeEvent(.episodeDeletedFromCloud, episode: episode)
        }

        func episodeUploadFinished(episodeUUID: String) {
            episodeEvent(.episodeUploadFinished, uuid: episodeUUID)
        }

        // MARK: - Up Next

        func episodeAddedToUpNext(episode: BaseEpisode, toTop: Bool) {
            track(.episodeAddedToUpNext, properties: ["episode_uuid": episode.uuid, "to_top": toTop])
        }

        func bulkAddToUpNext(count: Int, toTop: Bool) {
            track(.episodeBulkAddToUpNext, properties: ["episode_count": count, "to_top": toTop])
        }

        func episodeRemovedFromUpNext(episode: BaseEpisode) {
            episodeEvent(.episodeRemovedFromUpNext, episode: episode)
        }

        // MARK: - Private

        private var currentPlaybackSource: String {
            if let currentSource = currentSource {
                self.currentSource = nil
                return currentSource
            }

            return (getTopViewController() as? PlaybackSource)?.playbackSource ?? "unknown"
        }
    #endif
}

private extension AnalyticsEpisodeHelper {
    #if !os(watchOS)
        func episodeEvent(_ event: AnalyticsEvent, episode: BaseEpisode? = nil, uuid: String? = nil) {
            let episodeUUID: String
            if let episode {
                episodeUUID = episode.uuid
            }
            else if let uuid {
                episodeUUID = uuid
            }
            else {
                episodeUUID = "unknown"
            }

            track(event, properties: ["episode_uuid": episodeUUID])
        }

        func bulkEvent(_ event: AnalyticsEvent, count: Int) {
            track(event, properties: ["episode_count": count])
        }

        func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
            
                let defaultProperties: [String: Any] = ["source": self.currentPlaybackSource]
                let mergedProperties = defaultProperties.merging(properties ?? [:]) { current, _ in current }
                Analytics.track(event, properties: mergedProperties)
            }
        }
    
        func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
            guard UIApplication.shared.applicationState == .active else {
                return nil
            }
        
            if let nav = base as? UINavigationController {
                return getTopViewController(base: nav.visibleViewController)
            }
            else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopViewController(base: selected)
            }
            else if let presented = base?.presentedViewController {
                return getTopViewController(base: presented)
            }
            return base
        }
    #endif
}

private extension AnalyticsEpisodeHelper {
    func addNotificationObservers() {
        #if !os(watchOS)
            NotificationCenter.default.addObserver(forName: Constants.Notifications.episodeDownloaded, object: nil, queue: .main) { notification in
                // Verify the UUID is one that we're tracking
                guard let uuid = notification.object as? String, self.episodeDownloadQueue.contains(uuid) else {
                    return
                }

                // Verify that the file has finished downloading
                guard
                    let episode = DataManager.sharedManager.findEpisode(uuid: uuid),
                    let status = DownloadStatus(rawValue: episode.episodeStatus),
                    status == .downloaded
                else {
                    return
                }

                self.episodeDownloadQueue.remove(uuid)
                self.downloadFinished(episodeUUID: uuid)
            }

            NotificationCenter.default.addObserver(forName: ServerNotifications.userEpisodeUploadStatusChanged, object: nil, queue: .main) { notification in
                // Verify the UUID is one that we're tracking
                guard let uuid = notification.object as? String, self.episodeUploadQueue.contains(uuid) else {
                    return
                }

                // Verify that the file has finished uploading
                guard
                    let episode = DataManager.sharedManager.findUserEpisode(uuid: uuid),
                    let status = UploadStatus(rawValue: episode.uploadStatus),
                    status == .uploaded
                else {
                    return
                }

                self.episodeUploadQueue.remove(uuid)
                self.episodeUploadFinished(episodeUUID: uuid)
            }
        #endif
    }
}
