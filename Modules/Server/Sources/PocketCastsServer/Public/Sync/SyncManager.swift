import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

public class SyncManager {
    public class func isUserLoggedIn() -> Bool {
        if let email = ServerSettings.syncingEmail(), !email.isEmpty {
            return true
        }
        return false
    }

    public class func isFirstSyncInProgress() -> Bool {
        let lastSyncStartDate = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.lastSyncStartDate)
        let lastModifiedServerDate = UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.lastModifiedServerDate)

        return (lastSyncStartDate != nil && lastModifiedServerDate == nil)
    }

    public class func isRefreshInProgress() -> Bool {
        guard let lastRefreshStartDate = UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.lastRefreshStartTime) as? Date else {
            return false
        }
        guard let lastRefreshEndDate = UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.lastRefreshEndTime) as? Date else {
            return true
        }
        return lastRefreshStartDate.compare(lastRefreshEndDate) == .orderedDescending
    }

    /// Signs the user out
    /// - Parameter userInitiated: Whether the user initiated the sign out or not
    public class func signout(userInitiated: Bool = false) {
        // Notify any listeners that the user login state will be changing
        NotificationCenter.postOnMainThread(notification: .serverUserWillBeSignedOut, userInfo: ["user_initiated": userInitiated])

        clearTokensFromKeyChain()

        ServerSettings.setSyncingEmail(email: nil)
        ServerSettings.userId = nil

        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.lastModifiedServerDate)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.upNextServerLastModified)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.historyServerLastModified)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionPaid)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionPlatform)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionExpiryDate)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionAutoRenewing)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionGiftDays)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.marketingOptInNeedsSyncKey)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.marketingOptInKey)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgementNeedsSyncKey)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgement)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.subscriptionPodcasts)
        UserDefaults.standard.synchronize()

        ServerConfig.shared.syncDelegate?.cleanupCloudOnlyFiles()
    }

    public class func clearTokensFromKeyChain() {
        KeychainHelper.removeKey(ServerConstants.Values.syncingEmailKey)
        KeychainHelper.removeKey(ServerConstants.Values.syncingPasswordKey)
        KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
        KeychainHelper.removeKey(ServerConstants.Values.refreshTokenKey)
        KeychainHelper.removeKey(ServerConstants.Values.appleAuthUserIDKey)
    }

}

// MARK: - Sync Reason
public extension SyncManager {
    enum SyncingReason: String {
        case accountCreated
        case login
    }

    /// Defines a reason why a sync is being performed
    static var syncReason: SyncManager.SyncingReason? = nil
}
