import Foundation
import PocketCastsDataModel

extension AutoAddToUpNextViewController: PodcastSelectionDelegate {
    func bulkSelectionChange(selected: Bool) {
        var setting = Int32()

        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

        if selected {
            // Checks for existing AutoAddToUpNextSetting value before assigning a default value
            allPodcasts.forEach {podcast in
                if podcast.autoAddToUpNext == 0 {
                    let status = AutoAddToUpNextSetting.addLast.rawValue
                    DataManager.sharedManager.saveAutoAddToUpNext(podcastUuid: podcast.uuid, autoAddToUpNext: status)
                }
            }
        } else {
            setting = AutoAddToUpNextSetting.off.rawValue
            DataManager.sharedManager.saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: setting)
        }

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
