import UIKit

public class DateFormatHelper: NSObject {
    public static let sharedHelper = DateFormatHelper()

    private lazy var shortLocalizedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd MMMM")

        return formatter
    }()

    public lazy var justDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")

        return formatter
    }()

    private lazy var monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")

        return formatter
    }()

    public lazy var monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        return formatter
    }()

    private lazy var fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")

        return formatter
    }()

    private lazy var longElapsedFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropTrailing
        formatter.allowedUnits = [.day, .hour, .minute, .second]

        return formatter
    }()

    private lazy var singleDigitFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.allowsFractionalUnits = false
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute]

        return formatter
    }()

    // MARK: - 2 minutes, 30 seconds long elapsed time

    public func longElapsedTime(_ time: TimeInterval) -> String {
        if let formattedTime = longElapsedFormatter.string(from: time) {
            return formattedTime
        }

        return "0 seconds"
    }

    // MARK: - 2 days or 2 years or 3 seconds

    public func shortTimeRemaining(_ time: TimeInterval) -> String {
        if let formattedTime = singleDigitFormatter.string(from: round(time)) {
            return formattedTime
        }

        return "0 days"
    }

    // MARK: - Long d MMMM yyyy

    public func longLocalizedFormat(_ date: Date?) -> String {
        guard let date = date else { return "" }

        return fullDateFormatter.string(from: date)
    }

    // MARK: - Short dd MMMM

    public func shortLocalizedFormat(_ date: Date?) -> String {
        guard let date = date else { return "" }

        return shortLocalizedFormatter.string(from: date)
    }

    public func aboutPageFormat(_ date: Date?) -> String {
        guard let date = date else { return "" }

        if !date.isCurrentYear() {
            return fullDateFormatter.string(from: date)
        }

        return monthDayFormatter.string(from: date)
    }

    // MARK: - Tiny dd MMM

    public lazy var tinyLocalizedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    public func tinyLocalizedFormat(_ date: Date?) -> String {
        guard let date = date else { return "" }

        if !date.isCurrentYear() {
            return fullDateFormatter.string(from: date)
        } else if abs(date.timeIntervalSinceNow) > 6.days {
            return monthDayFormatter.string(from: date)
        } else {
            return justDayFormatter.string(from: date)
        }
    }

    // MARK: - JSON

    public lazy var localTimeJsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter
    }()

    private lazy var jsonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter
    }()

    public func jsonFormat(_ date: Date?) -> String {
        guard let date = date else { return "" }

        return jsonDateFormatter.string(from: date)
    }

    public func jsonDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }

        return jsonDateFormatter.date(from: string)
    }

    // MARK: - HTTP

    private lazy var httpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    public func httpDate(_ string: String?) -> Date? {
        guard let string = string else { return nil }

        return httpDateFormatter.date(from: string)
    }
}
