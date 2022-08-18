import Foundation

class AppLifecycleAnalytics {
    // Dependencies
    private let userDefaults: UserDefaults
    private let analytics: Analytics.Type

    /// The date the app was last opened, used for calculating time in app
    private var applicationOpenedTime: Date?

    init(userDefaults: UserDefaults = .standard, analytics: Analytics.Type = Analytics.self) {
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
}
