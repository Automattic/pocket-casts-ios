import Foundation
import PocketCastsUtils

/// Whether Playback 2026 is available: the single check every entry point (Podcasts sheet, Profile banner)
/// and the story flow use.
enum Playback2026 {
    /// The first moment Playback 2026 is available in App Store builds.
    static let availableFrom = date(year: 2026, month: 12, day: 1)

    /// The first moment Playback 2026 is no longer available in App Store builds.
    static let availableUntil = date(year: 2027, month: 2, day: 1)

    /// Playback 2026 is available when its feature flag is on and, in App Store builds, `now` is inside the date range.
    ///
    /// Debug and TestFlight builds skip the date range so the flow can be tested before and after it.
    static func isAvailable(
        now: Date = Date(),
        isFlagEnabled: Bool = FeatureFlag.playback2026.enabled,
        buildEnvironment: BuildEnvironment = .current
    ) -> Bool {
        guard isFlagEnabled else { return false }
        guard buildEnvironment == .appStore else { return true }
        return now >= availableFrom && now < availableUntil
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantFuture
    }
}
