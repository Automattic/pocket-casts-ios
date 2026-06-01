import AutomatticTracksEvents
import AutomatticTracksModel
import Foundation
import os
import PocketCastsServer
#if DEBUG
import PocketCastsUtils
#endif

class TracksAdapter: AnalyticsAdapter {
    private let userDefaults: UserDefaults

    /// Returns a UUID id to use if the user is in a logged out state
    private var anonymousUUID: String {
        AnonymousUUID.generate(userDefaults: userDefaults)
    }

    private let trackerTask: Task<TracksTracker, Never>

    init(
        userDefaults: UserDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId) ?? .standard,
        subscriptionData: TracksSubscriptionData = PocketCastsTracksSubscriptionData(),
        notificationCenter: NotificationCenter = .default,
        abTestProvider: ABTestProviding = ABTestProvider.shared
    ) {
        self.userDefaults = userDefaults

        trackerTask = Task {
            await TracksTracker(
                userDefaults: userDefaults,
                subscriptionData: subscriptionData,
                notificationCenter: notificationCenter,
                abTestProvider: abTestProvider
            )
        }
    }

    func track(name: String, properties: [String: Sendable]) async {
        await trackerTask.value.track(name: name, properties: properties)
    }
}

// MARK: - TracksTracker

/// Owns the underlying `TracksService` and performs the actual event tracking on its own
/// isolation domain. Constructed via an async init so the heavy `TracksContextManager`
/// setup runs off the launch path.
private actor TracksTracker {
    private let userDefaults: UserDefaults
    private let subscriptionData: TracksSubscriptionData
    private let notificationCenter: NotificationCenter
    private let abTestProvider: ABTestProviding
    private let tracksService: TracksService

    private var anonymousUUID: String {
        AnonymousUUID.generate(userDefaults: userDefaults)
    }

    private enum TracksConfig {
        static let prefix = "pcios"
        static let userKey = "pocketcasts:user_id"
        static let platform = "pocketcasts"
    }

    init(
        userDefaults: UserDefaults,
        subscriptionData: TracksSubscriptionData,
        notificationCenter: NotificationCenter,
        abTestProvider: ABTestProviding
    ) async {
        self.userDefaults = userDefaults
        self.subscriptionData = subscriptionData
        self.notificationCenter = notificationCenter
        self.abTestProvider = abTestProvider

        let context = TracksContextManager()
        tracksService = TracksService(contextManager: context)
        tracksService.platform = TracksConfig.platform
        tracksService.eventNamePrefix = TracksConfig.prefix
        tracksService.authenticatedUserTypeKey = TracksConfig.userKey

        TracksLogging.delegate = TracksAdapterLoggingDelegate.shared
#if DEBUG
        FileLog.shared.console("TracksAdapter anonymous UUID \(anonymousUUID)")
#endif
        // Setup the rest of the properties
        reloadExPlat()
        await updateUserProperties()
        addNotificationObservers()
        updateAuthenticationState()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func track(name: String, properties: [String: Sendable]) {
        #if DEBUG
        validateProperties(properties)
        #endif
        tracksService.trackEventName(name, withCustomProperties: properties)
    }

    private func validateProperties(_ properties: [String: Sendable]) {
        for key in properties.keys {
            if Self.reservedPropertyNames.contains(key) {
                assertionFailure("Tracks event properties key `\(key)` is reserved property name.")
                return
            }

            let value = properties[key]
            if !(value is Int || value is Int32 || value is Int64 || value is String || value is NSString || value is Double || value is Bool || value is Float) {
                assertionFailure("Tracks event properties value for `\(key)` must be of one the valid types: Int, String, Bool, Double, Float")
                return
            }
        }
    }

    @MainActor
    private func getDefaultProperties(with subscriptionData: TracksSubscriptionData) -> [String: AnyHashable] {
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
            Task { await self?.updateUserProperties() }
        }

        notificationCenter.addObserver(forName: .userLoginDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.updateAuthenticationState() }
        }
    }

    // List of reserved Property names that is defined here: https://github.com/Automattic/nosara/blob/master/ganymedes2/kafka_staging/src/main/scala/com/automattic/ganymedes2/streaming/tracks/schema/TracksEvent.scala
    private static let reservedPropertyNames = Set<String>([
        "timestamp",
        "year",
        "month",
        "day",
        "dateymd",
        "datetime",
        "logdateymd",
        "anonid",
        "userid",
        "useridtype",
        "userlang",
        "eventnamepartial",
        "eventname",
        "eventprops",
        "eventsource",
        "geoip",
        "geocountrycode",
        "geocountry",
        "georegion",
        "geocity",
        "geolatitude",
        "geolongitude",
        "logdate",
        "logtimestamp",
        "logmethod",
        "logreferrer",
        "requesttimestamp",
        "eventtimestamp",
        "browserlang",
        "browserfamilyversion",
        "browserfamily",
        "browserdocumentlocation",
        "browserdocumentreferrer",
        "useragent",
        "devicefamily",
        "deviceos",
        "blogid",
        "bloglang",
        "blogtimezone",
        "kafkatopic",
        "processingtimestamp",
        "etlmessage",
        "eventmarker",
        "record_ymdh"
    ])
}

private extension TracksTracker {
    func updateUserProperties() async {
        let properties = await getDefaultProperties(with: subscriptionData)
        for (key, value) in properties {
            tracksService.userProperties[key] = value
        }
    }

    func updateAuthenticationState() {
        if let userId = ServerSettings.userId {
            tracksService.switchToAuthenticatedUser(withUsername: nil, userID: userId, skipAliasEventCreation: false)
        } else {
            tracksService.switchToAnonymousUser(withAnonymousID: anonymousUUID)
        }
        reloadABTest()
    }

    func reloadExPlat() {
        abTestProvider.reloadExPlat(platform: tracksService.platform, oAuthToken: nil, userAgent: nil, anonId: anonymousUUID)
    }

    func reloadABTest() {
        Task { @MainActor [abTestProvider] in
            await abTestProvider.start()
        }
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
