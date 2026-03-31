import Foundation

class ServerNotificationsHelper {
    static let shared = ServerNotificationsHelper()

    func firePodcastRefreshFailed() {
        ServerSettings.setLastRefreshSucceeded(false)

        NotificationCenter.default.post(name: ServerNotifications.podcastRefreshFailed, object: nil)
    }

    func firePodcastRefreshSucceeded() {
        ServerSettings.setLastRefreshSucceeded(true)

        NotificationCenter.default.post(name: ServerNotifications.podcastsRefreshed, object: nil)
    }

    func firePodcastsUpdated() {
        // TODO: this is the same notification as above, since it's what the app expects, but in future should we make it its own thing?
        NotificationCenter.default.post(name: ServerNotifications.podcastsRefreshed, object: nil)
    }

    func fireSyncCompleted() {
        ServerSettings.setLastSyncSucceeded(true)
        SyncManager.syncReason = nil

        NotificationCenter.default.post(name: ServerNotifications.syncCompleted, object: nil)
    }

    func fireSyncFailed() {
        ServerSettings.setLastSyncSucceeded(false)
        SyncManager.syncReason = nil

        NotificationCenter.default.post(name: ServerNotifications.syncFailed, object: nil)
    }
}
