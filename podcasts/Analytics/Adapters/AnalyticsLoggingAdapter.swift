import Foundation
import PocketCastsUtils

/// Simple tracking adapter that just logs the event
struct AnalyticsLoggingAdapter: AnalyticsAdapter {
    func track(name: String, properties: [String: Sendable]) async {
        guard FeatureFlag.tracksLogging.enabled else { return }

        if properties.isEmpty {
            log("🔵 Tracked: \(name)")
        } else {
            log("🔵 Tracked: \(name) \(properties)")
        }
    }

    private func log(_ message: String) {
        FileLog.shared.addMessage(message)
    }
}
