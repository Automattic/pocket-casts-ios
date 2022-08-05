import AutomatticTracksEvents
import AutomatticTracksModel
import Foundation
import os
import PocketCastsServer
import UIKit

class TracksAdapter: AnalyticsAdapter {
    private let tracksService: TracksService

    private enum TracksConfig {
        static let prefix = "pcios"
        static let userKey = "pc:user_id"
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init() {
        let context = TracksContextManager()
        tracksService = TracksService(contextManager: context)
        tracksService.eventNamePrefix = TracksConfig.prefix
        tracksService.authenticatedUserTypeKey = TracksConfig.userKey

        TracksLogging.delegate = TracksAdapterLoggingDelegate()

        updateUserProperties()
        addNotificationObservers()

        #warning("TODO: Check for user authentication")
    }

    func track(name: String, properties: [AnyHashable: Any]?) {
        tracksService.trackEventName(name, withCustomProperties: properties)
    }

    private var defaultProperties: [String: AnyHashable] {
        let hasSubscription = SubscriptionHelper.hasActiveSubscription()
        let platform = SubscriptionHelper.subscriptionPlatform()
        let type = hasSubscription ? SubscriptionHelper.subscriptionType() : .none
        let frequency = hasSubscription ? SubscriptionHelper.subscriptionFrequencyValue() : .none

        return [
            // Subscription Keys
            "plus_has_subscription": hasSubscription,
            "plus_has_lifetime": SubscriptionHelper.hasLifetimeGift(),
            "plus_subscription_type": type.toString,
            "plus_subscription_platform": platform.toString,
            "plus_subscription_frequency": frequency.toString,
            
            // Accessibility
            "accessibility_voice_over_enabled": UIAccessibility.isVoiceOverRunning,
            "is_rtl_language": UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        ]
    }

    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserProperties), name: ServerNotifications.subscriptionStatusChanged, object: nil)
    }

    @objc func updateUserProperties() {
        // When being triggered from a notification this can end up on a background thread
        DispatchQueue.main.async {
            self.defaultProperties.forEach { (key: String, value: AnyHashable) in
                print("\(key): \(value)")
                self.tracksService.userProperties[key] = value
            }
        }
    }
}

struct TracksLoggingAdapter: AnalyticsAdapter {
    func track(name: String, properties: [AnyHashable: Any]?) {
        print("🪵 \(name)")
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
