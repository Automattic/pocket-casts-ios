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

// MARK: - Dynamic Event Name

private extension AnalyticsEvent {
    var eventName: String {
        return rawValue.toSnakeCaseFromCamelCase()
    }
}
