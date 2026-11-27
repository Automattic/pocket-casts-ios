import Foundation

extension Date {
    /// The time since this date, formatted for log messages, e.g. "1.25s".
    public var elapsedTimeDescription: String {
        String(format: "%.2fs", Date().timeIntervalSince(self))
    }
}
