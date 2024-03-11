import Foundation
import PocketCastsDataModel
import PocketCastsServer

class AnalyticsEpisodeHelper: AnalyticsCoordinator {
    static var shared = AnalyticsEpisodeHelper()

    // Internally track the episode UUIDs that the user is downloading or uploadiung
    private var episodeDownloadQueue: Set<String> = []
    private var episodeUploadQueue: Set<String> = []

    override init() {
        super.init()
        addNotificationObservers()
    }

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

    func downloadFailed(episodeUUID: String,
                        podcastUUID: String,
                        extraProperties: [String: Any]) {
        track(.episodeDownloadFailed, properties: ["episode_uuid": episodeUUID,
                                                   "podcast_uuid": podcastUUID,
                                                  ].merging(extraProperties, uniquingKeysWith: { (current, _) in return current }))
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
}

private extension AnalyticsEpisodeHelper {
    func episodeEvent(_ event: AnalyticsEvent, episode: BaseEpisode? = nil, uuid: String? = nil) {
        let episodeUUID: String
        if let episode {
            episodeUUID = episode.uuid
        } else if let uuid {
            episodeUUID = uuid
        } else {
            episodeUUID = "unknown"
        }

        track(event, properties: ["episode_uuid": episodeUUID])
    }

    func bulkEvent(_ event: AnalyticsEvent, count: Int) {
        track(event, properties: ["episode_count": count])
    }
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
