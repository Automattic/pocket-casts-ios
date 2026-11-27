import Foundation

/// Parses ISO 8601 dates such as `2024-01-01T12:00:00Z`, the format the podcast cache server uses. Safe to call from any thread.
public enum ISO8601DateParser {
    private static let style = Date.ISO8601FormatStyle()

    public static func date(from string: String) -> Date? {
        try? style.parse(string)
    }
}
