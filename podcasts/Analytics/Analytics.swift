import Foundation
import os
import PocketCastsUtils
import EventHorizonSDK

class Analytics {
    static let shared = Analytics()
#if DEBUG
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PocketCasts", category: "Analytics")
#endif
    private var adapters: [AnalyticsAdapter]?
#if !os(watchOS) && !APPCLIP && !os(tvOS)
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
#if !os(watchOS) && !APPCLIP && !os(tvOS)
    static func add(analyticsAppThemeProvider: AnalyticsAppThemeProviding) {
        Self.shared.analyticsAppThemeProvider = analyticsAppThemeProvider
    }
#endif

    /// Convenience method to call Analytics.track*
    static func track(_ event: AnalyticsEvent, properties: [String: Sendable]? = nil) {
        Self.shared.track(event, properties: properties)
    }

    func track(_ event: AnalyticsEvent, properties: [String: Sendable]? = nil) {
        _track(event.eventName, properties: properties)
    }

    private func _track(_ eventName: String, properties: [String: Sendable]? = nil) {
        var properties: [String: Sendable] = (properties ?? [:]).mapValues { value in
            (value as? AnalyticsDescribable)?.analyticsDescription ?? value
        }
#if !os(watchOS) && !APPCLIP && !os(tvOS)
        if FeatureFlag.appThemePropertiesLogging.enabled {
            analyticsAppThemeProvider?.appThemeProperties.forEach { key, value in
                properties[key] = value
            }
        }
#endif
        Task { [adapters] in
            for adapter in adapters ?? [] {
                await adapter.track(name: eventName, properties: properties)
            }
#if DEBUG
            Self.logger.debug("[Analytics] \(eventName, privacy: .public) - \(properties.count, privacy: .public) properties")
#endif
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

// MARK: Analytics (EventHorizon)

extension Analytics {
    static func send(_ event: some EventHorizonSDK.Trackable) {
        let properties = event.analyticsProperties.mapValues { String(describing: $0) }
        Analytics.shared._track(event.analyticsName, properties: properties)
    }
}

// MARK: - Analytics + Source

extension Analytics {
    static func track(_ event: AnalyticsEvent, source: Sendable, properties: [String: Sendable]? = nil) {
        var sourceProperties = properties ?? [:]
        sourceProperties["source"] = source

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
#if !os(watchOS) && !APPCLIP && !os(tvOS)
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
#if !os(watchOS) && !APPCLIP && !os(tvOS)
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
    func track(name: String, properties: [String: Sendable]) async
}

// MARK: - Dynamic Event Name

extension AnalyticsEvent {
    var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
