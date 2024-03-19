import Foundation
import PocketCastsDataModel
import PocketCastsServer

class BadgeHelper {
    deinit {
        teardown()
    }

    func setup() {
        let notCenter = NotificationCenter.default
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.filterChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.episodePlayStatusChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.episodeArchiveStatusChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.episodeStarredChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.episodeDownloadStatusChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.manyEpisodesChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: ServerNotifications.podcastsRefreshed, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.opmlImportCompleted, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.episodeDownloaded, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.playbackTrackChanged, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.playbackEnded, object: nil)
        notCenter.addObserver(self, selector: #selector(updateBadge), name: Constants.Notifications.playbackStarted, object: nil)
    }

    func teardown() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateBadge() {
        guard let badgeSetting = Settings.appBadge else { return }

        let pushOn = NotificationsHelper.shared.pushEnabled()

        if badgeSetting == .off && !pushOn { return } // user has both the badge and push turned off, don't attempt to badge their app. Results in iOS 8 push message request popup

        if badgeSetting == .off || !pushOn {
            clearBadge(clearNotificationsToo: false)
        } else if badgeSetting == .totalUnplayed {
            let unplayedCount = DataManager.sharedManager.count(query: "SELECT COUNT(e.id) FROM SJEpisode e LEFT JOIN SJPodcast p ON p.id = e.podcast_id WHERE p.subscribed = 1 AND e.playingStatus == 1 AND e.archived = 0", values: nil)
            setBadgeTo(unplayedCount)
        } else if badgeSetting == .newSinceLastOpened {
            guard let lastClosedDate = UserDefaults.standard.object(forKey: Constants.UserDefaults.lastAppCloseDate) as? Date else {
                clearBadge(clearNotificationsToo: false)

                return
            }

            let newCount = DataManager.sharedManager.count(query: "SELECT COUNT(e.id) FROM SJEpisode e LEFT JOIN SJPodcast p ON p.id = e.podcast_id WHERE p.subscribed = 1 AND e.playingStatus == 1 AND e.archived = 0 AND e.addedDate > ?", values: [lastClosedDate])
            setBadgeTo(newCount)
        } else if badgeSetting == .filterCount {
            guard let filterId = Settings.appBadgeFilterUuid else {
                Settings.appBadge = .off

                return
            }

            guard let filter = DataManager.sharedManager.findFilter(uuid: filterId) else {
                Settings.appBadge = .off

                return
            }

            let episodeCount = DataManager.sharedManager.episodeCount(forFilter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries())
            setBadgeTo(episodeCount)
        }
    }

    func clearNotifications() {
        clearBadge(clearNotificationsToo: true)
        updateBadge()
    }

    private func clearBadge(clearNotificationsToo: Bool) {
        DispatchQueue.main.async {
            let currentBadgeValue = UIApplication.shared.applicationIconBadgeNumber
            if clearNotificationsToo, currentBadgeValue == 0 {
                // if the badge is already 0, set it to 1 to clear out things like notifications, setting a badge that's 0 to 0 won't do that
                UIApplication.shared.applicationIconBadgeNumber = 1
            }
            if !clearNotificationsToo, currentBadgeValue == 0 { return }

            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    private func setBadgeTo(_ badgeNumber: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badgeNumber
        }
    }
}
