import Foundation

protocol AnalyticsAdapter {
    func track(name: String, properties: [AnyHashable: Any]?)
}

class Analytics {
    static let shared = Analytics()
    private var adapters: [AnalyticsAdapter]?

    static func register(adapters: [AnalyticsAdapter]) {
        Self.shared.adapters = adapters
    }

    /// Unregisters all the registered adapters, disabling analytics
    static func unregister() {
        Self.shared.adapters = nil
    }

    /// Convenience method to call Analytics.shared.track*
    static func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        Self.shared.track(event, properties: properties)
    }

    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        adapters?.forEach {
            $0.track(name: event.eventName, properties: properties)
        }
    }
}

// MARK: - Opt out/in

extension Analytics {
    func optOutOfAnalytics() {
        Analytics.track(.analyticsOptOut)
        Settings.setAnalytics(optOut: true)
        Analytics.unregister()
    }

    func optInOfAnalytics() {
        #if !os(watchOS)
            Settings.setAnalytics(optOut: false)
            (UIApplication.shared.delegate as? AppDelegate)?.setupAnalytics()
            Analytics.track(.analyticsOptIn)
        #endif
    }
}

// MARK: - Dynamic Event Name

private extension AnalyticsEvent {
    var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
