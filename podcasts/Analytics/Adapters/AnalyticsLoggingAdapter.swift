import Foundation
import os

/// Simple tracking adapter that just logs the event
struct AnalyticsLoggingAdapter: AnalyticsAdapter {
    static let logger = Logger()

    func track(name: String, properties: [AnyHashable: Any]?) {
        guard let properties = properties as? [String: Any] else {
            Self.logger.debug("🔵 Tracked: \(name)")
            return
        }

        Self.logger.debug("🔵 Tracked: \(name) \(properties)")
    }
}
