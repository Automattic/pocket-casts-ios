import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

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

        // Intentionally does not anchor `Settings.encourageAccountCreationReferenceDate`. The
        // Encourage Account Creation modal targets any logged-out user regardless of how they became
        // logged out, so it should surface after a sign-out (user-initiated or forced). The 60-day
        // interval still governs repeat showings, and the onboarding grace period only applies to a
        // brand-new user who declined initial onboarding without an account.
    }
}
