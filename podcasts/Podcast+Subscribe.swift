import PocketCastsDataModel
import PocketCastsUtils
import PocketCastsServer

extension Podcast {
    func subscribe() {
        subscribed = 1
        syncStatus = SyncStatus.notSynced.rawValue
        autoDownloadSetting = (FeatureFlag.autoDownloadOnSubscribe.enabled && Settings.autoDownloadEnabled() && Settings.autoDownloadOnFollow() ? AutoDownloadSetting.latest : AutoDownloadSetting.off).rawValue
        DataManager.sharedManager.save(podcast: self)
        ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: self, setDefaults: true, autoDownloadLimit: Settings.autoDownloadOnFollow() ? Settings.autoDownloadLimits().rawValue : 0)
    }
}
