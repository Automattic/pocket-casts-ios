import AutomatticTracksEvents
import AutomatticTracksModel
import Foundation
import os
import PocketCastsServer

class TracksAdapter: AnalyticsAdapter {
    // Dependencies
    private let userDefaults: UserDefaults
    private let subscriptionData: TracksSubscriptionData
    private let notificationCenter: NotificationCenter

    // Config
    private let tracksService: TracksService

    private enum TracksConfig {
        static let prefix = "pcios"
        static let userKey = "pocketcasts:user_id"
        static let anonymousUUIDKey = "TracksAnonymousUUID"
    }

    /// Returns a UUID id to use if the user is in a logged out state
    ///
    private var anonymousUUID: String {
        let key = TracksConfig.anonymousUUIDKey

        // Generate a new UUID if there isn't currently one
        guard let uuid = userDefaults.string(forKey: key) else {
            let uuid = UUID().uuidString
            userDefaults.set(uuid, forKey: key)
            return uuid
        }

        return uuid
    }

    deinit {
        notificationCenter.removeObserver(self)
        tracksService.clearQueuedEvents()
    }

    init(userDefaults: UserDefaults = .standard,
         subscriptionData: TracksSubscriptionData = PocketCastsTracksSubscriptionData(),
         notificationCenter: NotificationCenter = .default) {
        self.userDefaults = userDefaults
        self.subscriptionData = subscriptionData
        self.notificationCenter = notificationCenter

        let context = TracksContextManager()
        tracksService = TracksService(contextManager: context)
        tracksService.eventNamePrefix = TracksConfig.prefix
        tracksService.authenticatedUserTypeKey = TracksConfig.userKey

        TracksLogging.delegate = TracksAdapterLoggingDelegate.shared

        // Setup the rest of the properties
        updateUserProperties()
        addNotificationObservers()
        updateAuthenticationState()
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        tracksService.trackEventName(name, withCustomProperties: properties)
    }

    private var defaultProperties: [String: AnyHashable] {
        let hasSubscription = subscriptionData.hasActiveSubscription()
        let platform = subscriptionData.subscriptionPlatform()
        let type = hasSubscription ? subscriptionData.subscriptionType() : .none
        let tier = subscriptionData.subscriptionTier
        let frequency = hasSubscription ? subscriptionData.subscriptionFrequency() : .none
        let hasLifetime = subscriptionData.hasLifetimeGift()

        return [
            // General keys
            "user_is_logged_in": SyncManager.isUserLoggedIn(),

            // Subscription Keys
            "plus_has_subscription": hasSubscription,
            "plus_has_lifetime": hasLifetime,
            "plus_subscription_type": type.analyticsDescription,
            "plus_subscription_tier": tier.analyticsDescription,
            "plus_subscription_platform": platform.analyticsDescription,
            "plus_subscription_frequency": frequency.analyticsDescription,

            // Accessibility
            "is_rtl_language": UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft,

            // Large is the default size
            "has_dynamic_font_size": UIApplication.shared.preferredContentSizeCategory != .large
        ]
    }

    // MARK: - Notification Handlers

    private func addNotificationObservers() {
        notificationCenter.addObserver(forName: ServerNotifications.subscriptionStatusChanged, object: nil, queue: .main) { [weak self] _ in
            self?.updateUserProperties()
        }

        notificationCenter.addObserver(forName: .userLoginDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.updateAuthenticationState()
        }
    }
}

private extension TracksAdapter {
    func updateUserProperties() {
        defaultProperties.forEach { (key: String, value: AnyHashable) in
            self.tracksService.userProperties[key] = value
        }
    }

    func updateAuthenticationState() {
        guard let userId = ServerSettings.userId else {
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousUUID)
            return
        }

        tracksService.switchToAuthenticatedUser(withUsername: nil, userID: userId, skipAliasEventCreation: false)
    }
}

// MARK: - TracksLoggingDelegate

private class TracksAdapterLoggingDelegate: NSObject, TracksLoggingDelegate {
    static let shared = TracksAdapterLoggingDelegate()
    private static let logger = Logger()

    func logError(_ str: String) {
        Self.logger.error("\(str)")
    }

    func logWarning(_ str: String) {
        Self.logger.warning("\(str)")
    }

    func logInfo(_ str: String) {
        Self.logger.info("\(str)")
    }

    func logDebug(_ str: String) {
        Self.logger.debug("\(str)")
    }

    func logVerbose(_ str: String) {
        Self.logger.log("\(str)")
    }
}
