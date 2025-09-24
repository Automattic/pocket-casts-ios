import Foundation
import PocketCastsUtils

class Analytics {
    static let shared = Analytics()
    private var adapters: [AnalyticsAdapter]?
#if !os(watchOS) && !APPCLIP
    var analyticsAppThemeProvider: AnalyticsAppThemeProviding?
#endif

    // Whether we have adapters registered or not
    var adaptersRegistered: Bool = false

    static func register(adapters: [AnalyticsAdapter]) {
        Self.shared.adapters = adapters
        Self.shared.setAdaptersRegisteredStatus(true)
    }

    /// Unregisters all the registered adapters, disabling analytics
    static func unregister() {
        Self.shared.adapters = nil
        Self.shared.setAdaptersRegisteredStatus(false)
    }
#if !os(watchOS) && !APPCLIP
    static func add(analyticsAppThemeProvider: AnalyticsAppThemeProviding) {
        Self.shared.analyticsAppThemeProvider = analyticsAppThemeProvider
    }
#endif

    /// Convenience method to call Analytics.shared.track*
    static func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        Self.shared.track(event, properties: properties)
    }

    func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        var newProperties = (properties ?? [:]).mapValues { (($0 as? AnalyticsDescribable)?.analyticsDescription) ?? $0 }
#if !os(watchOS) && !APPCLIP
        if FeatureFlag.appThemePropertiesLogging.enabled {
            analyticsAppThemeProvider?.appThemeProperties.forEach { key, value in
                newProperties[key] = value
            }
        }
#endif
        adapters?.forEach {
            $0.track(name: event.eventName, properties: newProperties)
        }
    }

    private static func logCurrentAdapters() {
#if DEBUG
        FileLog.shared.console("Analytics adapters: \(Self.shared.adapters ?? [])")
#endif
    }

    fileprivate func setAdaptersRegisteredStatus(_ value: Bool) {
        adaptersRegistered = value
        Self.logCurrentAdapters()
    }
}

// MARK: - Analytics + Source

extension Analytics {
    static func track(_ event: AnalyticsEvent, source: Any, properties: [AnyHashable: Any]? = nil) {
        var sourceProperties = properties ?? [:]
        sourceProperties.updateValue(source, forKey: "source")

        track(event, properties: sourceProperties)
    }
}

// MARK: - Opt out/in

extension Analytics {
    func optOutOfAnalytics() {
        Analytics.track(.analyticsOptOut)
        Settings.setAnalytics(optOut: true)
        refreshRegistered()
    }

    func optInOfAnalytics() {
#if !os(watchOS) && !APPCLIP
        Settings.setAnalytics(optOut: false)
        setAdaptersRegisteredStatus(false)
        (UIApplication.shared.delegate as? AppDelegate)?.setupAnalytics()
        Analytics.track(.analyticsOptIn)
#endif
    }

    func refreshRegistered() {
        if Settings.analyticsOptOut() {
            Analytics.unregister()
        }
#if !os(watchOS) && !APPCLIP
        (UIApplication.shared.delegate as? AppDelegate)?.setupAnalytics()
#endif
        FileLog.shared.addMessage("Analytics: Refreshed Registered Adapters")
        Analytics.logCurrentAdapters()
    }
}

// MARK: - Protocols

/// Allows an object to determine how its described in the context of analytics
protocol AnalyticsDescribable {
    var analyticsDescription: String { get }
}

/// Classes can implement this to determine their own logic on how to handle each event
protocol AnalyticsAdapter {
    var isThirdPartyAdapter: Bool { get }
    func track(name: String, properties: [AnyHashable: Any]?)
}

extension AnalyticsAdapter {
    var isThirdPartyAdapter: Bool {
        false
    }
}

// MARK: - Dynamic Event Name

extension AnalyticsEvent {
    var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
