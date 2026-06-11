import Foundation
import OSLog

/// Tracking adapter that prints every event to the unified logging system (Console / Xcode).
///
/// Logs under the running app's bundle identifier, so each target (iOS, tvOS, App Clip…)
/// surfaces its events under its respective subsystem, all in the `Analytics` category.
/// Filter with `subsystem:<bundle id> category:Analytics`.
struct AnalyticsOSLogAdapter: AnalyticsAdapter {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PocketCasts", category: "Analytics")

    func track(name: String, properties: [String: Sendable]) async {
        if properties.isEmpty {
            Self.logger.debug("🔵 Tracked: \(name, privacy: .public)")
        } else {
            Self.logger.debug("🔵 Tracked: \(name, privacy: .public) \(String(describing: properties), privacy: .private)")
        }
    }
}
