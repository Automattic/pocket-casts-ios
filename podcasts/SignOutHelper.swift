import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

enum SignOutHelper {
    static func signout() {
        let paidPodcasts = DataManager.shared.allPaidPodcasts()
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.supportName)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.supportEmail)
        SyncManager.signout(userInitiated: true)
        UserEpisodeManager.cleanupCloudOnlyFiles()
        Settings.setLoginDetailsUpdated()
        paidPodcasts.forEach { PodcastManager.shared.unsubscribe(podcast: $0) }

        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
        NotificationCenter.postOnMainThread(notification: .userLoginDidChange)
    }
}
