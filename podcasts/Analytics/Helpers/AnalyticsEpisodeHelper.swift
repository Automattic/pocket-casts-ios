import Foundation
import PocketCastsDataModel
import PocketCastsServer

class AnalyticsEpisodeHelper: AnalyticsCoordinator {
    static var shared = AnalyticsEpisodeHelper()

    // Internally track the episode UUIDs that the user is downloading or uploadiung
    private var episodeDownloadQueue: Set<String> = []
    private var episodeUploadQueue: Set<String> = []
    // Keep track of where a download was initiated so completion/failure logs use the same source
    private let episodeDownloadSources = ThreadSafeDictionary<String, AnalyticsSource>()

    override init() {
        super.init()
        addNotificationObservers()
    }

    func setup() {
        // Empty method just to ensure that sigleton is initialized
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
        clearDownloadSource(for: episodeUUID)
        episodeEvent(.episodeDownloadCancelled, uuid: episodeUUID)
    }

    func downloaded(episodeUUID: String) {
        let source = cacheDownloadSource(for: episodeUUID)
        episodeDownloadQueue.insert(episodeUUID)
        currentSource = source
        episodeEvent(.episodeDownloadQueued, uuid: episodeUUID)
    }

    func downloadFinished(episodeUUID: String) {
        let source = consumeDownloadSource(for: episodeUUID)
        if let source {
            currentSource = source
        }
        episodeEvent(.episodeDownloadFinished, uuid: episodeUUID)
    }

    func downloadFailed(episodeUUID: String,
                        podcastUUID: String,
                        extraProperties: [String: Any]) {
        let source = consumeDownloadSource(for: episodeUUID)
        if let source {
            currentSource = source
        }
        track(.episodeDownloadFailed, properties: ["episode_uuid": episodeUUID,
                                                   "podcast_uuid": podcastUUID,
                                                  ].merging(extraProperties, uniquingKeysWith: { (current, _) in return current }))
    }

    func bulkDownloadEpisodes(episodes: [BaseEpisode]) {
        let uuids = episodes.map { $0.uuid }
        let source = cacheDownloadSource(for: uuids)
        episodeDownloadQueue.formUnion(uuids)
        currentSource = source
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

    func bulkRemoveFromListeningHistory(count: Int) {
        bulkEvent(.episodeRemovedListeningHistory, count: count)
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

    func episodeUploadFailed(episodeUUID: String) {
        episodeEvent(.episodeUploadFailed, uuid: episodeUUID)
    }

    // MARK: - Up Next

    func episodeAddedToUpNext(episode: BaseEpisode, toTop: Bool) {
        track(.episodeAddedToUpNext, properties: ["episode_uuid": episode.uuid, "podcast_uuid": episode.parentIdentifier(), "to_top": toTop])
    }

    func bulkAddToUpNext(count: Int, toTop: Bool) {
        track(.episodeBulkAddToUpNext, properties: ["episode_count": count, "to_top": toTop])
    }

    func episodeRemovedFromUpNext(episode: BaseEpisode) {
        episodeEvent(.episodeRemovedFromUpNext, episode: episode)
    }
}

private extension AnalyticsEpisodeHelper {
    func cacheDownloadSource(for episodeUUID: String) -> AnalyticsSource {
        let source = currentAnalyticsSource
        episodeDownloadSources[episodeUUID] = source
        return source
    }

    func cacheDownloadSource(for episodeUUIDs: [String]) -> AnalyticsSource {
        let source = currentAnalyticsSource
        episodeUUIDs.forEach { episodeDownloadSources[$0] = source }
        return source
    }

    func consumeDownloadSource(for episodeUUID: String) -> AnalyticsSource? {
        let source = episodeDownloadSources[episodeUUID]
        episodeDownloadSources[episodeUUID] = nil
        return source
    }

    func clearDownloadSource(for episodeUUID: String) {
        episodeDownloadSources.removeValue(forKey: episodeUUID)
    }

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
                    let status = UploadStatus(rawValue: episode.uploadStatus)
                else {
                    return
                }

                switch status {
                case .uploaded:
                    self.episodeUploadQueue.remove(uuid)
                    self.episodeUploadFinished(episodeUUID: uuid)
                case .uploadFailed:
                    self.episodeUploadFailed(episodeUUID: uuid)
                default:
                    break
                }
            }
        #endif
    }
}
