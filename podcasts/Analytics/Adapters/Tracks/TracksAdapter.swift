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
        static let uuidInactivityTimeout: TimeInterval = 30.minutes
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

    /// The date the last event was tracked, used to determine when to regenerate the UUID
    private var lastEventDate: Date?

    deinit {
        notificationCenter.removeObserver(self)
    }

    init(userDefaults: UserDefaults = .standard,
         subscriptionData: TracksSubscriptionData = PocketCastsTracksSubscriptionData(),
         notificationCenter: NotificationCenter = .default)
    {
        self.userDefaults = userDefaults
        self.subscriptionData = subscriptionData
        self.notificationCenter = notificationCenter

        let context = TracksContextManager()
        tracksService = TracksService(contextManager: context)
        tracksService.eventNamePrefix = TracksConfig.prefix
        tracksService.authenticatedUserTypeKey = TracksConfig.userKey

        TracksLogging.delegate = TracksAdapterLoggingDelegate()

        // Reset the anonymous UUID on each new analytics session
        resetAnonymousUUID()

        // Setup the rest of the
        updateUserProperties()
        addNotificationObservers()
        updateAuthenticationState()
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        regenerateAnonymousUUIDIfNeeded()
        tracksService.trackEventName(name, withCustomProperties: properties)

        // Update the last event date so we can monitor the UUID timeout
        lastEventDate = Date()
    }

    private var defaultProperties: [String: AnyHashable] {
        let hasSubscription = subscriptionData.hasActiveSubscription()
        let platform = subscriptionData.subscriptionPlatform()
        let type = hasSubscription ? subscriptionData.subscriptionType() : .none
        let frequency = hasSubscription ? subscriptionData.subscriptionFrequency() : .none
        let hasLifetime = subscriptionData.hasLifetimeGift()

        return [
            // General keys
            "user_is_logged_in": SyncManager.isUserLoggedIn(),
            
            // Subscription Keys
            "plus_has_subscription": hasSubscription,
            "plus_has_lifetime": hasLifetime,
            "plus_subscription_type": type.analyticsDescription,
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
        tracksService.switchToAnonymousUser(withAnonymousID: anonymousUUID)
    }

    func resetAnonymousUUID() {
        userDefaults.set(nil, forKey: TracksConfig.anonymousUUIDKey)
    }

    /// Checks to see if the time since the last tracking event is greater than the timeout
    /// If it is, we reset the stored anonymous UUID so a new one will be generated for the event
    func regenerateAnonymousUUIDIfNeeded() {
        // No last event date, don't regenerate we're on a first launch
        guard let lastEventDate = lastEventDate else {
            return
        }

        let secondsSince = Date().timeIntervalSince(lastEventDate)

        // The timeout limit hasn't been hit yet
        guard secondsSince >= TracksConfig.uuidInactivityTimeout else {
            return
        }

        // Over the timeout, reset the UUID
        resetAnonymousUUID()
        updateAuthenticationState()
    }
}

// MARK: - TracksLoggingDelegate

private class TracksAdapterLoggingDelegate: NSObject, TracksLoggingDelegate {
    static let logger = Logger()

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
