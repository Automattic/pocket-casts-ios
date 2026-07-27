import Foundation
import PocketCastsDataModel
import PocketCastsServer
import Combine
import UserNotifications

class BadgeHelper {
    deinit {
        teardown()
    }

    private var cancelable: Cancellable?

    func setup() {
        let notifications: [NSNotification.Name] = [
            Constants.Notifications.playlistChanged,
            Constants.Notifications.episodePlayStatusChanged,
            Constants.Notifications.episodeArchiveStatusChanged,
            Constants.Notifications.episodeStarredChanged,
            Constants.Notifications.episodeDownloadStatusChanged,
            Constants.Notifications.manyEpisodesChanged,
            ServerNotifications.podcastsRefreshed,
            Constants.Notifications.opmlImportCompleted,
            Constants.Notifications.episodeDownloaded,
            Constants.Notifications.playbackTrackChanged,
            Constants.Notifications.playbackEnded,
            Constants.Notifications.playbackStarted
        ]

        let mergedNotifications = notifications
            .map { NotificationCenter.default.publisher(for: $0) }
            .reduce(Empty<Notification, Never>().eraseToAnyPublisher()) { acc, pub in
                acc.merge(with: pub).eraseToAnyPublisher()
            }
            .debounce(for: .seconds(3), scheduler: RunLoop.main)

        cancelable = mergedNotifications.sink { [weak self] _ in
            self?.updateBadge()
        }
    }

    func teardown() {
        cancelable?.cancel()
        cancelable = nil
    }

    @objc func updateBadge() {
        guard let badgeSetting = Settings.appBadge else { return }

        let pushOn = NotificationsHelper.shared.pushEnabled()

        if badgeSetting == .off && !pushOn { return } // user has both the badge and push turned off, don't attempt to badge their app. Results in iOS 8 push message request popup

        if badgeSetting == .off || !pushOn {
            clearBadge()
        } else if badgeSetting == .totalUnplayed {
            let unplayedCount = DataManager.sharedManager.count(query: "SELECT COUNT(e.id) FROM SJEpisode e LEFT JOIN SJPodcast p ON p.id = e.podcast_id WHERE p.subscribed = 1 AND e.playingStatus == 1 AND e.archived = 0", values: nil)
            setBadgeTo(unplayedCount)
        } else if badgeSetting == .newSinceLastOpened {
            guard let lastClosedDate = UserDefaults.standard.object(forKey: Constants.UserDefaults.lastAppCloseDate) as? Date else {
                clearBadge()

                return
            }

            let newCount = DataManager.sharedManager.count(query: "SELECT COUNT(e.id) FROM SJEpisode e LEFT JOIN SJPodcast p ON p.id = e.podcast_id WHERE p.subscribed = 1 AND e.playingStatus == 1 AND e.archived = 0 AND e.addedDate > ?", values: [lastClosedDate])
            setBadgeTo(newCount)
        } else if badgeSetting == .filterCount {
            guard let playlistId = Settings.appBadgeFilterUuid else {
                Settings.appBadge = .off

                return
            }

            guard let playlist = DataManager.sharedManager.findPlaylist(uuid: playlistId) else {
                Settings.appBadge = .off

                return
            }

            let episodeCount = DataManager.sharedManager.episodeCount(for: playlist, episodeUuidToAdd: playlist.episodeUuidToAddToQueries())
            setBadgeTo(episodeCount)
        }
    }

    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    private func setBadgeTo(_ badgeNumber: Int) {
        UNUserNotificationCenter.current().setBadgeCount(badgeNumber)
    }
}
