import Foundation
import PocketCastsUtils

/// Simple tracking adapter that just logs the event
struct AnalyticsLoggingAdapter: AnalyticsAdapter {
    func track(name: String, properties: [AnyHashable: Any]?) {
        guard FeatureFlag.tracksLogging.enabled else { return }

        guard let properties = properties as? [String: Any] else {
            log("🔵 Tracked: \(name)")
            return
        }

        log("🔵 Tracked: \(name) \(properties)")
    }

    private func log(_ message: String) {
        FileLog.shared.addMessage(message)
    }
}
