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

    /// - Parameter completion: called once the system has acknowledged the badge write, or immediately if the badge was left untouched.
    func updateBadge(completion: (() -> Void)? = nil) {
        guard let badgeCount = badgeCount() else {
            completion?()

            return
        }

        UNUserNotificationCenter.current().setBadgeCount(badgeCount) { _ in
            completion?()
        }
    }

    /// The number to badge the app with, or `nil` if the badge shouldn't be touched at all.
    private func badgeCount() -> Int? {
        guard let badgeSetting = Settings.appBadge else { return nil }

        let pushOn = NotificationsHelper.shared.pushEnabled()

        if badgeSetting == .off && !pushOn { return nil } // user has both the badge and push turned off, don't attempt to badge their app. Results in iOS 8 push message request popup

        if !pushOn { return 0 }

        switch badgeSetting {
        case .off:
            return 0
        case .totalUnplayed:
            return DataManager.sharedManager.count(query: "SELECT COUNT(e.id) FROM SJEpisode e LEFT JOIN SJPodcast p ON p.id = e.podcast_id WHERE p.subscribed = 1 AND e.playingStatus == 1 AND e.archived = 0", values: nil)
        case .newSinceLastOpened:
            guard let lastClosedDate = UserDefaults.standard.object(forKey: Constants.UserDefaults.lastAppCloseDate) as? Date else { return 0 }

            return DataManager.sharedManager.count(query: "SELECT COUNT(e.id) FROM SJEpisode e LEFT JOIN SJPodcast p ON p.id = e.podcast_id WHERE p.subscribed = 1 AND e.playingStatus == 1 AND e.archived = 0 AND e.addedDate > ?", values: [lastClosedDate])
        case .filterCount:
            guard let playlistId = Settings.appBadgeFilterUuid,
                  let playlist = DataManager.sharedManager.findPlaylist(uuid: playlistId) else {
                Settings.appBadge = .off

                return nil
            }

            return DataManager.sharedManager.episodeCount(for: playlist, episodeUuidToAdd: playlist.episodeUuidToAddToQueries())
        }
    }
}
