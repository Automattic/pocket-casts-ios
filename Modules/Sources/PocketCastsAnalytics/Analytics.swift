import Foundation
import PocketCastsUtils
import EventHorizonSDK

public class Analytics {
    public static let shared = Analytics()
    private var adapters: [AnalyticsAdapter]?
    var analyticsAppThemeProvider: AnalyticsAppThemeProviding?

    // Whether we have adapters registered or not
    public private(set) var adaptersRegistered: Bool = false

    public static func register(adapters: [AnalyticsAdapter]) {
        Self.shared.adapters = adapters
        Self.shared.setAdaptersRegisteredStatus(true)
    }

    /// Unregisters all the registered adapters, disabling analytics
    public static func unregister() {
        Self.shared.adapters = nil
        Self.shared.setAdaptersRegisteredStatus(false)
    }

    public static func add(analyticsAppThemeProvider: AnalyticsAppThemeProviding) {
        Self.shared.analyticsAppThemeProvider = analyticsAppThemeProvider
    }

    /// Convenience method to call Analytics.track*
    public static func track(_ event: AnalyticsEvent, properties: [String: Sendable]? = nil) {
        Self.shared.track(event, properties: properties)
    }

    public func track(_ event: AnalyticsEvent, properties: [String: Sendable]? = nil) {
        _track(event.eventName, properties: properties)
    }

    private func _track(_ eventName: String, properties: [String: Sendable]? = nil) {
        var properties: [String: Sendable] = (properties ?? [:]).mapValues { value -> Sendable in
            if let describable = value as? AnalyticsDescribable {
                return describable.analyticsDescription
            }
            return value
        }
        if let analyticsAppThemeProvider, FeatureFlag.appThemePropertiesLogging.enabled {
            analyticsAppThemeProvider.appThemeProperties.forEach { key, value in
                properties[key] = value
            }
        }
        Task { [adapters] in
            for adapter in adapters ?? [] {
                await adapter.track(name: eventName, properties: properties)
            }
        }
    }

    public static func logCurrentAdapters() {
#if DEBUG
        FileLog.shared.console("Analytics adapters: \(Self.shared.adapters ?? [])")
#endif
    }

    public func setAdaptersRegisteredStatus(_ value: Bool) {
        adaptersRegistered = value
        Self.logCurrentAdapters()
    }
}

// MARK: Analytics (EventHorizon)

extension Analytics {
    public static func send(_ event: some EventHorizonSDK.Trackable) {
        let properties = event.analyticsProperties.mapValues { String(describing: $0) }
        Analytics.shared._track(event.analyticsName, properties: properties)
    }
}

// MARK: - Analytics + Source

extension Analytics {
    public static func track(_ event: AnalyticsEvent, source: Sendable, properties: [String: Sendable]? = nil) {
        var sourceProperties = properties ?? [:]
        sourceProperties["source"] = source

        track(event, properties: sourceProperties)
    }
}

// MARK: - Protocols

/// Allows an object to determine how its described in the context of analytics
public protocol AnalyticsDescribable {
    var analyticsDescription: String { get }
}

/// Classes can implement this to determine their own logic on how to handle each event
public protocol AnalyticsAdapter {
    func track(name: String, properties: [String: Sendable]) async
}

public protocol AnalyticsAppThemeProviding {
    var appThemeProperties: [String: Sendable] { get }
}

// MARK: - Dynamic Event Name

extension AnalyticsEvent {
    public var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
