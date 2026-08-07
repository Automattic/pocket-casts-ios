import Foundation
import PocketCastsUtils

/// Simple tracking adapter that writes the event to the log file.
///
/// The unified logging system is covered by ``AnalyticsOSLogAdapter``, so events
/// are never echoed to the console from here.
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
        FileLog.shared.addMessage(message, to: .file)
    }
}
