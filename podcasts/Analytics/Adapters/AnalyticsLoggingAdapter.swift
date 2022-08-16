import Foundation
import os

/// Simple tracking adapter that just logs the event
struct AnalyticsLoggingAdapter: AnalyticsAdapter {
    static let logger = Logger()

    func track(name: String, properties: [AnyHashable: Any]?) {
        Self.logger.info("🔵 \(name)")
    }
}
