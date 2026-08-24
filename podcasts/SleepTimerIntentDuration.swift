import Foundation

enum SleepTimerIntentDuration {
    static func boundedValue(_ duration: TimeInterval) -> TimeInterval? {
        guard duration.isFinite, duration > 0 else {
            return nil
        }

        return duration.clamped(to: Constants.Limits.minSleepTime...Constants.Limits.maxSleepTime)
    }

    static func resolvedValue(
        _ selectedDuration: Measurement<UnitDuration>?,
        defaultDuration: TimeInterval
    ) -> TimeInterval {
        guard let selectedDuration else {
            return defaultDuration
        }

        let seconds = selectedDuration.converted(to: .seconds).value
        guard seconds.isFinite, seconds > 0 else {
            return defaultDuration
        }

        return seconds
    }

    static func migratedValue(_ legacySeconds: Int?, defaultDuration: TimeInterval) -> TimeInterval {
        guard let legacySeconds, legacySeconds > 0 else {
            return defaultDuration
        }

        return TimeInterval(legacySeconds)
    }
}
