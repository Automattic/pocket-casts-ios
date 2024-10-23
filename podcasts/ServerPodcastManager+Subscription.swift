import PocketCastsServer
import PocketCastsUtils

extension ServerPodcastManager {

    func subscribe(to podcastUuid: String, completion: ((Bool) -> ())?) {
        let limits = Settings.autoDownloadEnabled() && FeatureFlag.autoDownloadOnSubscribe.enabled ? Settings.autoDownloadLimits().rawValue : 0
        self.addFromUuid(podcastUuid: podcastUuid, subscribe: true, autoDownloads: limits, completion: completion)
    }

    func subscribeFromItunesId(_ itunesId: Int, completion: ((Bool, String?) -> ())?) {
        let limits = Settings.autoDownloadEnabled() && FeatureFlag.autoDownloadOnSubscribe.enabled ? Settings.autoDownloadLimits().rawValue : 0
        self.addFromiTunesId(itunesId, subscribe: true, autoDownloads: limits, completion: completion)
    }
}
