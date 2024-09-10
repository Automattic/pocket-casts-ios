import Foundation

public class TimeFormatter {
    public static let shared = TimeFormatter()

    private lazy var colonFormatterMinutes: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]

        return formatter
    }()

    private lazy var colonFormatterHours: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]

        return formatter
    }()

    private lazy var shortFormatMinutes: DateComponentsFormatter = {
        localizedFormatter(style: .abbreviated, allowedUnits: [.minute])
    }()

    private lazy var shortFormatHours: DateComponentsFormatter = {
        localizedFormatter(style: .abbreviated, allowedUnits: [.hour])
    }()

    private lazy var shortTimeFormatter: DateComponentsFormatter = {
        localizedFormatter(style: .abbreviated, allowedUnits: [.minute, .hour])
    }()

    private lazy var subMinuteFormatter: DateComponentsFormatter = {
        localizedFormatter(style: .abbreviated, allowedUnits: [.second])
    }()

    private lazy var appleFormatterSeconds: DateComponentsFormatter = {
        localizedFormatter(style: .full, allowedUnits: [.second])
    }()

    private lazy var appleFormatterMinutes: DateComponentsFormatter = {
        localizedFormatter(style: .full, allowedUnits: [.minute])
    }()

    private lazy var appleFormatterHours: DateComponentsFormatter = {
        localizedFormatter(style: .full, allowedUnits: [.hour])
    }()

    private lazy var appleFormatterDays: DateComponentsFormatter = {
        localizedFormatter(style: .full, allowedUnits: [.day])
    }()

    private lazy var appleFormatterYears: DateComponentsFormatter = {
        localizedFormatter(style: .full, allowedUnits: [.year])
    }()

    private lazy var minutesHoursFormatter: DateComponentsFormatter = {
        localizedFormatter(style: .full, allowedUnits: [.hour, .minute])
    }()

    private lazy var minutesHoursFormatterMedium: DateComponentsFormatter = {
        localizedFormatter(style: .short, allowedUnits: [.hour, .minute])
    }()

    public func playTimeFormat(time: TimeInterval, showSeconds: Bool = true) -> String {
        if time.isNaN || !time.isFinite { return "0:00" }

        if time < 1.hours {
            let formatter = showSeconds ? colonFormatterMinutes : shortFormatMinutes
            return formatter.string(from: time) ?? "0:00"
        }

        if showSeconds {
            return colonFormatterHours.string(from: time) ?? "0:00"
        } else {
            if #available(iOS 16.0, watchOS 9.0, *) {
                return Duration.seconds(time).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
            } else {
                return shortTimeFormatter.string(from: time) ?? "0:00"
            }
        }
    }

    public func singleUnitFormattedShortestTime(time: TimeInterval) -> String {
        if time.isNaN || !time.isFinite { return "" }

        if time < 1.minutes {
            return subMinuteFormatter.string(from: time) ?? ""
        } else if time < 1.hours {
            return shortFormatMinutes.string(from: time) ?? ""
        } else {
            return shortFormatHours.string(from: time) ?? ""
        }
    }

    public func multipleUnitFormattedShortTime(time: TimeInterval) -> String {
        if time.isNaN || !time.isFinite { return "" }

        if time < 60.seconds {
            return subMinuteFormatter.string(from: time) ?? ""
        }

        return shortTimeFormatter.string(from: time) ?? ""
    }

    public func minutesHoursFormatted(time: TimeInterval) -> String {
        if time.isNaN || !time.isFinite { return "" }

        return minutesHoursFormatter.string(from: time) ?? ""
    }

    public func minutesFormatted(time: TimeInterval) -> String {
        if time.isNaN || !time.isFinite { return "" }

        return appleFormatterMinutes.string(from: time) ?? ""
    }

    private lazy var relativeFormatter = RelativeDateTimeFormatter()

    public func appleStyleElapsedString(date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    public func appleStyleTillString(date: Date) -> String? {
        let time = date.timeIntervalSinceNow
        var timeStr: String?
        if time <= 1.minute {
            timeStr = appleFormatterSeconds.string(from: time)
        } else if time <= 1.hour {
            timeStr = appleFormatterMinutes.string(from: time)
        } else if time <= 1.days {
            timeStr = appleFormatterHours.string(from: time)
        } else if time <= 365.days {
            timeStr = appleFormatterDays.string(from: time)
        } else {
            timeStr = appleFormatterYears.string(from: time)
        }

        return timeStr
    }

    public class func currentUTCTimeInMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func createUsFormatter(allowedUnits: NSCalendar.Unit) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = allowedUnits
        formatter.zeroFormattingBehavior = [.dropAll]

        return formatter
    }

    private func localizedFormatter(style: DateComponentsFormatter.UnitsStyle, allowedUnits: NSCalendar.Unit) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = style
        formatter.allowedUnits = allowedUnits
        formatter.zeroFormattingBehavior = [.dropAll]

        return formatter
    }
}
