import Foundation
import PocketCastsDataModel
import PocketCastsServer

class SignOutHelper {
    class func signout() {
        let paidPodcasts = DataManager.sharedManager.allPaidPodcasts()
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.supportName)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.supportEmail)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey)
        SyncManager.signout(userInitiated: true)
        UserEpisodeManager.cleanupCloudOnlyFiles()
        Settings.setLoginDetailsUpdated()
        paidPodcasts.forEach { PodcastManager.shared.unsubscribe(podcast: $0) }

        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
        NotificationCenter.postOnMainThread(notification: .userLoginDidChange)
    }
}
