import Foundation
import PocketCastsDataModel

extension AutoAddToUpNextViewController: PodcastSelectionDelegate {
    func bulkSelectionChange(selected: Bool) {
        let setting = selected ? AutoAddToUpNextSetting.addLast.rawValue : AutoAddToUpNextSetting.off.rawValue
        DataManager.sharedManager.saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: setting)
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        allPodcasts.forEach { NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: $0.uuid) }

        reloadDownloadedPodcasts()
        mainTable.reloadData()
    }

    func podcastSelected(podcast: String) {
        DataManager.sharedManager.saveAutoAddToUpNext(podcastUuid: podcast, autoAddToUpNext: AutoAddToUpNextSetting.addLast.rawValue)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast)

        reloadDownloadedPodcasts()
        mainTable.reloadData()
    }

    func podcastUnselected(podcast: String) {
        DataManager.sharedManager.saveAutoAddToUpNext(podcastUuid: podcast, autoAddToUpNext: AutoAddToUpNextSetting.off.rawValue)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast)

        reloadDownloadedPodcasts()
        mainTable.reloadData()
    }

    func didChangePodcasts() {
        Analytics.track(.settingsAutoAddUpNextPodcastsChanged)
    }
}
