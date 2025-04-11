import PocketCastsServer
import PocketCastsUtils

struct DebugInfo {
    static func string(optOut: Bool) -> String {
        let syncEmail: String
        if SyncManager.isUserLoggedIn(), let email = ServerSettings.syncingEmail() {
            syncEmail = email
        } else {
            syncEmail = "Not logged in"
        }

        let now = Date()
        let localTime = DateFormatHelper.sharedHelper.localTimeJsonDateFormatter.string(from: now)
        let gmtTime = DateFormatHelper.sharedHelper.jsonFormat(now)

        var debugString = """
        App Version: \(Settings.appVersion())
        Device: \(DeviceUtil.identifier)
        OS: \(DeviceUtil.systemVersion ?? "Unknown")
        Local Time: \(localTime)
        UTC Time: \(gmtTime)
        Watch App Installed: \(WatchManager.shared.isWatchAppInstalled ? "yes" : "no")\n
        """

        guard !optOut else { return debugString }
        debugString += """
        Sync Email: \(syncEmail)
        App ID: \(Settings.uniqueAppId() ?? "Unknown")

        Auto Download On: \(Settings.autoDownloadEnabled() ? "yes" : "no")
        Auto Download Only on Wifi: \(Settings.autoDownloadMobileDataAllowed() ? "no" : "yes")
        Warn Before Using Data: \(Settings.mobileDataAllowed() ? "no" : "yes")
        Auto Download Up Next:  \(Settings.downloadUpNextEpisodes() ? "yes" : "no")
        Auto Archive Played Episodes after: \(ArchiveHelper.archiveTimeToText(Settings.autoArchivePlayedAfter()))
        Auto Archive Inactive Episodes after: \(ArchiveHelper.archiveTimeToText(Settings.autoArchiveInactiveAfter()))
        Auto Archive Starred Episodes: \(Settings.archiveStarredEpisodes())
        Uploaded Episode Count: \(ServerSettings.customStorageNumFiles())
        """

        return debugString
    }
}
