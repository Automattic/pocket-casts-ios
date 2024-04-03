import Foundation
import PocketCastsUtils
import PocketCastsDataModel

public class ServerSettings {
    // MARK: - Last Update Status

    private static let lastSyncSuccess = "LastSyncSuccess"
    public class func lastSyncSucceeded() -> Bool {
        if let succeeded = UserDefaults.standard.value(forKey: lastSyncSuccess) as? Bool {
            return succeeded
        }

        return true
    }

    public class func setLastSyncSucceeded(_ succeeded: Bool) {
        UserDefaults.standard.set(succeeded, forKey: lastSyncSuccess)
    }

    private static let lastRefreshSuccess = "LastRefreshSuccess"
    public class func lastRefreshSucceeded() -> Bool {
        if let succeeded = UserDefaults.standard.value(forKey: lastRefreshSuccess) as? Bool {
            return succeeded
        }

        return true
    }

    public class func setLastRefreshSucceeded(_ succeeded: Bool) {
        UserDefaults.standard.set(succeeded, forKey: lastRefreshSuccess)
    }

    // MARK: - Skip Forward

    private static let skipForwardAmount = "JumpForwardAmountInSeconds"
    private static let skipForwardNeedsSync = "JumpForwardSynced"
    public class func setSkipForwardTime(_ time: Int, syncChange: Bool = true) {
        UserDefaults.standard.set(time, forKey: ServerSettings.skipForwardAmount)

        if syncChange {
            UserDefaults.standard.set(true, forKey: ServerSettings.skipForwardNeedsSync)
        }
    }

    public class func skipForwardTime() -> Int {
        UserDefaults.standard.integer(forKey: ServerSettings.skipForwardAmount)
    }

    public class func skipForwardNeedsSyncing() -> Bool {
        UserDefaults.standard.bool(forKey: ServerSettings.skipForwardNeedsSync)
    }

    public class func setSkipForwardSynced() {
        UserDefaults.standard.set(false, forKey: ServerSettings.skipForwardNeedsSync)
    }

    // MARK: - Skip Back

    private static let skipBackAmount = "JumpBackAmountInSeconds"
    private static let skipBackNeedsSync = "JumpBackSynced"
    public class func setSkipBackTime(_ time: Int, syncChange: Bool = true) {
        UserDefaults.standard.set(time, forKey: ServerSettings.skipBackAmount)

        if syncChange {
            UserDefaults.standard.set(true, forKey: ServerSettings.skipBackNeedsSync)
        }
    }

    public class func skipBackTime() -> Int {
        UserDefaults.standard.integer(forKey: ServerSettings.skipBackAmount)
    }

    public class func skipBackNeedsSyncing() -> Bool {
        UserDefaults.standard.bool(forKey: ServerSettings.skipBackNeedsSync)
    }

    public class func setSkipBackSynced() {
        UserDefaults.standard.set(false, forKey: ServerSettings.skipBackNeedsSync)
    }

    // MARK: Home Grid Order

    private static let homeGridSortOrderKey = "SJPodcastLibrarySort"
    private static let homeGridSortModifiedKey = "SJPodcastLibrarySortModified"
    public class func homeGridSortOrderNeedsSyncing() -> Bool {
        UserDefaults.standard.bool(forKey: ServerSettings.homeGridSortModifiedKey)
    }

    public class func setHomeGridSortOrder(_ order: Int, syncChange: Bool = false) {
        UserDefaults.standard.set(order, forKey: homeGridSortOrderKey)
        if syncChange {
            UserDefaults.standard.set(true, forKey: homeGridSortModifiedKey)
        }
    }

    public class func setHomeGridSortOrderSynced() {
        UserDefaults.standard.set(false, forKey: homeGridSortModifiedKey)
    }

    public class func homeGridSortOrder() -> Int {
        UserDefaults.standard.integer(forKey: homeGridSortOrderKey)
    }

    // MARK: Home Grid Refresh

    private static let homeGridNeedsRefreshKey = "SJHomeGridRefreshRequired"
    public class func setHomeGridNeedsRefresh(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: homeGridNeedsRefreshKey)
    }

    public class func homeGridNeedsRefresh() -> Bool {
        UserDefaults.standard.bool(forKey: homeGridNeedsRefreshKey)
    }

    // MARK: Clear Listening History Date

    public class func setLastClearHistoryDate(_ value: Date?) {
        if let newDate = value {
            UserDefaults.standard.set(newDate, forKey: ServerConstants.UserDefaults.lastClearHistoryDate)
        } else {
            UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.lastClearHistoryDate)
        }
    }

    public class func lastClearHistoryDate() -> Date? {
        UserDefaults.standard.value(forKey: ServerConstants.UserDefaults.lastClearHistoryDate) as? Date
    }

    // MARK: Marketing Opt In

    public class func setMarketingOptIn(_ value: Bool) {
        if FeatureFlag.newSettingsStorage.enabled {
            SettingsStore.appSettings.marketingOptIn = value
        }
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.marketingOptInKey)
        UserDefaults.standard.set(true, forKey: ServerConstants.UserDefaults.marketingOptInNeedsSyncKey)
    }

    public class func marketingOptIn() -> Bool {
        if FeatureFlag.newSettingsStorage.enabled {
            return SettingsStore.appSettings.marketingOptIn
        } else {
            return UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.marketingOptInKey)
        }
    }

    public class func marketingOptInNeedsSyncing() -> Bool {
        UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.marketingOptInNeedsSyncKey)
    }

    public class func marketingOptInSynced() {
        UserDefaults.standard.set(false, forKey: ServerConstants.UserDefaults.marketingOptInNeedsSyncKey)
    }

    // MARK: Date of Latest UnsentSubscription Purchase Receipt

    private static let iapUnverifiedPurchaseReceipDatetKey = "SJIapDateUnverifiedPurchaseReceipt"
    public class func setIapUnverifiedPurchaseReceiptDate(_ value: Date?) {
        UserDefaults.standard.set(value, forKey: iapUnverifiedPurchaseReceipDatetKey)
    }

    public class func iapUnverifiedPurchaseReceiptDate() -> Date? {
        UserDefaults.standard.object(forKey: iapUnverifiedPurchaseReceipDatetKey) as? Date
    }

    // MARK: Files last modified

    public class func setFilesLastModified(_ value: String) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.filesLastModifiedKey)
    }

    public class func filesLastModified() -> String? {
        UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.filesLastModifiedKey)
    }

    public class func removeFilesLastModifiedKey() {
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.filesLastModifiedKey)
    }

    private static let filesUsageLastModifiedKey = "UserFilesUsageLastModified"

    public class func setFilesUsageLastModified(_ value: String) {
        UserDefaults.standard.set(value, forKey: filesUsageLastModifiedKey)
    }

    public class func filesUsageLastModified() -> String? {
        UserDefaults.standard.string(forKey: filesUsageLastModifiedKey)
    }

    // MARK: Custom Storage limit from user

    public class func setCustomStorageUserLimit(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.Values.customStorageUserLimit)
    }

    public class func customStorageUserLimit() -> Int {
        UserDefaults.standard.integer(forKey: ServerConstants.Values.customStorageUserLimit)
    }

    // MARK: Custom Storage used on server

    public class func setCustomStorageUsed(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.Values.customStorageUsed)
    }

    public class func customStorageUsed() -> Int {
        UserDefaults.standard.integer(forKey: ServerConstants.Values.customStorageUsed)
    }

    // MARK: Custom Storage number of files on server

    public class func setCustomStorageNumFiles(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.Values.customStorageNumFiles)
    }

    public class func customStorageNumFiles() -> Int {
        UserDefaults.standard.integer(forKey: ServerConstants.Values.customStorageNumFiles)
    }

    // User files autodownload
    private static let userEpisodeAutoDownloadKey = "UserEpisodeAutoDownload"
    public class func userEpisodeAutoDownload() -> Bool {
        UserDefaults.standard.bool(forKey: userEpisodeAutoDownloadKey)
    }

    public class func setUserEpisodeAutoDownload(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userEpisodeAutoDownloadKey)
    }

    // User files autodownload on wifi
    private static let userEpisodeOnlyOnWifiKey = "UserEpisodeOnlyOnWifi"
    public class func userEpisodeOnlyOnWifi() -> Bool {
        UserDefaults.standard.bool(forKey: userEpisodeOnlyOnWifiKey)
    }

    public class func setUserEpisodeOnlyOnWifi(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: userEpisodeOnlyOnWifiKey)
    }

    public class func syncingEmail() -> String? {
        KeychainHelper.string(for: ServerConstants.Values.syncingEmailKey)
    }

    public class func setSyncingEmail(email: String?) {
        if let email = email {
            KeychainHelper.save(string: email, key: ServerConstants.Values.syncingEmailKey, accessibility: kSecAttrAccessibleAfterFirstUnlock)
        } else {
            KeychainHelper.removeKey(ServerConstants.Values.syncingEmailKey)
        }
    }

    // The two methods below should only be used for migration purposes, it's the old way of storing email addresses we don't use anymore
    public class func syncingEmailLegacy() -> String? {
        UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.syncingEmailLegacy)
    }

    public class func removeLegacySyncingEmail() {
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.syncingEmailLegacy)
    }

    public class func saveSyncingPassword(_ password: String) {
        KeychainHelper.save(string: password, key: ServerConstants.Values.syncingPasswordKey, accessibility: kSecAttrAccessibleAfterFirstUnlock)
    }

    public class func syncingPassword() -> String? {
        KeychainHelper.string(for: ServerConstants.Values.syncingPasswordKey)
    }

    public class func lastRefreshStartTime() -> Date? {
        UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.lastRefreshStartTime) as? Date
    }

    public class func lastRefreshEndTime() -> Date? {
        UserDefaults.standard.object(forKey: ServerConstants.UserDefaults.lastRefreshEndTime) as? Date
    }

    public class func clearLastSyncTime() {
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.lastSyncTime)
    }

    // Push Token
    public class func pushToken() -> String? {
        UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.pushToken)
    }

    public class func setPushToken(token: String) {
        UserDefaults.standard.set(token, forKey: ServerConstants.UserDefaults.pushToken)
    }

    public class func removePushToken() {
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.pushToken)
    }

    // MARK: - Auto add to Up Next Limit

    public static let autoAddLimitKey = "AutoAddToUpNextLimit"
    public class func autoAddToUpNextLimit() -> Int {
        if FeatureFlag.newSettingsStorage.enabled {
            Int(SettingsStore.appSettings.autoUpNextLimit)
        } else {
            UserDefaults.standard.integer(forKey: autoAddLimitKey)
        }
    }

    public class func setAutoAddToUpNextLimit(_ limit: Int) {
        if FeatureFlag.newSettingsStorage.enabled {
            SettingsStore.appSettings.autoUpNextLimit = Int32(limit)
        }
        UserDefaults.standard.setValue(limit, forKey: autoAddLimitKey)
    }

    public static let onAutoAddLimitReachedKey = "AutoAddLimitReachedKey"
    public class func onAutoAddLimitReached() -> AutoAddLimitReachedAction {
        if FeatureFlag.newSettingsStorage.enabled {
            return SettingsStore.appSettings.autoUpNextLimitReached
        } else {
            let storedValue = UserDefaults.standard.integer(forKey: onAutoAddLimitReachedKey)

            return AutoAddLimitReachedAction(rawValue: Int32(storedValue)) ?? .stopAdding
        }
    }

    public class func setOnAutoAddLimitReached(action: AutoAddLimitReachedAction) {
        if FeatureFlag.newSettingsStorage.enabled {
            SettingsStore.appSettings.autoUpNextLimitReached = action
        }
        UserDefaults.standard.setValue(action.rawValue, forKey: onAutoAddLimitReachedKey)
    }

    public class func syncSettings() {
        guard SyncManager.isUserLoggedIn(), ServerSettings.marketingOptInNeedsSyncing() || SubscriptionHelper.subscriptionGiftAcknowledgementNeedsSyncing() else { return }

        ApiServerHandler.shared.syncSettings()
    }
}

// MARK: - Authentication Support

public extension ServerSettings {
    class var userId: String? {
        get {
            UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.userId)
        }

        set {
            UserDefaults.standard.set(newValue, forKey: ServerConstants.UserDefaults.userId)
        }
    }

    class var syncingV2Token: String? {
        get {
            KeychainHelper.string(for: ServerConstants.Values.syncingV2TokenKey)
        }

        set {
            KeychainHelper.save(string: newValue, key: ServerConstants.Values.syncingV2TokenKey, accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }
    }

    class var refreshToken: String? {
        get {
            KeychainHelper.string(for: ServerConstants.Values.refreshTokenKey)
        }

        set {
            KeychainHelper.save(string: newValue, key: ServerConstants.Values.refreshTokenKey, accessibility: kSecAttrAccessibleAfterFirstUnlock)
        }
    }
}
