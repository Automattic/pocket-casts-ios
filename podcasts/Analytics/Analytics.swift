import Foundation

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
        let newProperties = properties?.mapValues { (($0 as? AnalyticsDescribable)?.analyticsDescription) ?? $0 }
        adapters?.forEach {
            $0.track(name: event.eventName, properties: newProperties)
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

// MARK: - Protocols

/// Allows an object to determine how its described in the context of analytics
protocol AnalyticsDescribable {
    var analyticsDescription: String { get }
}

/// Classes can implement this to determine their own logic on how to handle each event
protocol AnalyticsAdapter {
    func track(name: String, properties: [AnyHashable: Any]?)
}

// MARK: - Dynamic Event Name

private extension AnalyticsEvent {
    var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
