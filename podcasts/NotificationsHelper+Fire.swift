import Foundation

extension NotificationsHelper {
    func firePodcastRefreshFailed() {
        Settings.setLastRefreshSucceeded(false)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastRefreshFailed)
    }

    func firePodcastRefreshSucceeded() {
        Settings.setLastRefreshSucceeded(true)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastsRefreshed)
    }

    func firePodcastsUpdated() {
        // TODO: this is the same notification as above, since it's what the app expects, but in future we should make it its own thing
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastsRefreshed)
    }

    func fireSyncCompleted() {
        Settings.setLastSyncSucceeded(true)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.syncCompleted)
    }

    func fireSyncFailed() {
        Settings.setLastSyncSucceeded(false)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.syncFailed)
    }
}
