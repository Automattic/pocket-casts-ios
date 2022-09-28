import Foundation
import PocketCastsDataModel

class AnalyticsEpisodeHelper {
    static var shared = AnalyticsEpisodeHelper()
    
    /// Sometimes the playback source can't be inferred, just inform it here
    var currentSource: String?

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
            episodeEvent(.episodeDownloaded, uuid: episodeUUID)
        }

        func bulkDownloadEpisodes(count: Int) {
            bulkEvent(.episodeBulkDownloaded, count: count)
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
            episodeEvent(.episodeUploaded, uuid: episodeUUID)
        }

        func episodeUploadCancelled(episodeUUID: String) {
            episodeEvent(.episodeUploadCancelled, uuid: episodeUUID)
        }

        func episodeDeletedFromCloud(episode: BaseEpisode) {
            episodeEvent(.episodeDeletedFromCloud, episode: episode)
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
