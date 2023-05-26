import Foundation

extension Double {
    /// Returns a localized time description
    ///
    /// Eg.: 5400 will return "1 hour 30 min"
    public var localizedTimeDescription: String? {
        let days = Int(safeDouble: self / 86400)
        let hours = Int(safeDouble: self / 3600) - (days * 24)
        let mins = Int(safeDouble: self / 60) - (hours * 60) - (days * 24 * 60)
        let secs = Int(safeDouble: self.truncatingRemainder(dividingBy: 60))
        var output = [String]()

        if let daysHours = formatDaysHours(days: days, hours: hours) {
            output.append(daysHours)
        }

        if days > 0, hours > 0 {
            return output.first ?? ""
        }

        let secondsForDisplay = hours < 1 ? secs : 0
        if let minsSeconds = formatMinsSeconds(mins: mins, secs: secondsForDisplay) {
            output.append(minsSeconds)
        }

        if output.count == 0 {
            let components = DateComponents(calendar: Calendar.current, second: secs)
            return DateComponentsFormatter.localizedString(from: components, unitsStyle: .full)
        }

        return output.joined(separator: " ")
    }

    func formatDaysHours(days: Int, hours: Int) -> String? {
        guard days > 0 || hours > 0 else { return nil }
        let components = DateComponents(calendar: Calendar.current, day: days, hour: hours)
        return DateComponentsFormatter.localizedString(from: components, unitsStyle: .full)?.replacingOccurrences(of: ",", with: "")
    }

    func formatMinsSeconds(mins: Int, secs: Int) -> String? {
        guard mins > 0 else { return nil }
        let components = DateComponents(calendar: Calendar.current, minute: mins, second: secs)
        return DateComponentsFormatter.localizedString(from: components, unitsStyle: .short)?.replacingOccurrences(of: ",", with: "")
    }
}

extension Double {
    public typealias TimeFormatValueType = (Double, TimeFormatUnit)

    /// Converts a number of seconds to the nearest time value between: days, hours, minutes, and seconds
    /// and returns the converted value and the closest unit
    ///
    /// For Example: 129600 will return 1.5 as the value and .day as the unit
    public var timeFormatValues: TimeFormatValueType {
        switch self {
        case 1.day...:
            return (scaleDown(value: self, by: 1.day), .day)

        case 1.hour...:
            return (scaleDown(value: self, by: 1.hour), .hour)

        case 1.minute...:
            return (scaleDown(value: self, by: 1.minute), .minute)

        default:
            return (scaleDown(value: self, by: 1.second), .second)
        }
    }

    public enum TimeFormatUnit {
        case day, hour, minute, second
    }

    private func scaleDown(value: Double, by amount: Double) -> Double {
        ((value / amount) * 10.0).rounded() / 10.0
    }
}
