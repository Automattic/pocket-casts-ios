import Foundation

class AppLifecycleAnalytics {
    // Dependencies
    private let userDefaults: UserDefaults
    private let analytics: Analytics

    /// The date the app was last opened, used for calculating time in app
    private var applicationOpenedTime: Date?

    init(userDefaults: UserDefaults = .standard, analytics: Analytics = Analytics.shared) {
        self.userDefaults = userDefaults
        self.analytics = analytics
    }
}

// MARK: - App Opened/Closed

extension AppLifecycleAnalytics {
    func didBecomeActive() {
        /**
         The didBecomeActive event cant be fired even if the user views a system overlay such as the
         notifications, control center, or when multitasking on iPad.

         This happens without firing a didEnterBackground event, and since we reset the
         applicationOpenedTime property to nil in didEnterBackground, we can then check if it's not nil here and ignore
         triggering the app opened event.
         */
        guard applicationOpenedTime == nil else {
            return
        }

        applicationOpenedTime = Date()

        analytics.track(.applicationOpened)
    }

    func didEnterBackground() {
        var properties: [String: Any] = [:]

        // Calculate how long the app was opened for
        if let openTime = applicationOpenedTime {
            let timeInApp = round(Date().timeIntervalSince(openTime))
            properties = ["time_in_app": timeInApp.description]
        }

        analytics.track(.applicationClosed, properties: properties)
        applicationOpenedTime = nil
    }
}

// MARK: - App Install/Updates

extension AppLifecycleAnalytics {
    /// Checks whether we need to track an app install or app update
    func checkApplicationInstalledOrUpgraded() {
        // Don't check for install or upgrade if protected data isn't available yet
        //
        // If the app is launched "in the background" and protected data is enabled then the analytics won't
        // be enabled and we may miss some events.

        // When the user opens the app directly the event will be tracked. 
        guard UIApplication.shared.isProtectedDataAvailable else { return }

        let currentVersion = Settings.appVersion()

        defer {
            // Set the current version in the user defaults
            userDefaults.set(currentVersion, forKey: Constants.UserDefaults.lastRunVersion)
            userDefaults.synchronize()
        }

        // If there is no previous version, then record this as an install
        guard let lastRunVersion = tryToDetermineLastRunVersion() else {
            analytics.track(.applicationInstalled)
            return
        }

        // If the versions are not the same, then record this as an upgrade
        guard lastRunVersion != currentVersion else {
            return
        }

        analytics.track(.applicationUpdated, properties: ["previous_version": lastRunVersion])
    }

    private func tryToDetermineLastRunVersion() -> String? {
        if let lastRunVersion = userDefaults.string(forKey: Constants.UserDefaults.lastRunVersion) {
            return lastRunVersion
        }

        // Define a user defaults key -> app version to see if we can guess which previous version the user was running
        // The versionKeys come from the AppDelegate+Defaults and are only set after the app is launched for the first time on that version
        // Order matters, these are ordered from newest to oldest versions
        // We won't need to add anymore to this, since we now track the last opened as of (7.21)
        let versionMap: KeyValuePairs = [
            "v7_20_1_Ghost_Fix": "7.20.1",
            "FoldersInitialRun": "7.20.0",
            "v7_19_1Run": "7.19.1",
            "v7_16Run": "7.16.0",
            "v7_15Run": "7.15.0",
            "v7_12Run": "7.12.0",
            "v7_11Run": "7.11.0",
            "v7_3Run": "7.3.0"
        ]

        let version = versionMap.first { key, _ in
            userDefaults.bool(forKey: key)
        }

        // If we can't determine which version then default to no version
        guard let version = version else {
            return nil
        }

        return version.value
    }
}
