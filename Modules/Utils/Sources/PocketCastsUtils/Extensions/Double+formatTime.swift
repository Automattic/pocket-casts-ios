import Foundation

extension Double {
    /// Returns a localized time description
    ///
    /// Eg.: 5400 will return "1 hour 30 min"
    public var localizedTimeDescription: String? {
        calculateDescription(useFullUnits: false)
    }

    /// Returns a localized time description using the full units for all description
    ///
    /// Eg.: 88479 will return "1 day 34 minutes 29 seconds"
    public var localizedTimeDescriptionFullUnits: String? {
        calculateDescription(useFullUnits: true)
    }

    private func calculateDescription(useFullUnits: Bool) -> String? {
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
        if let minsSeconds = formatMinsSeconds(mins: mins, secs: secondsForDisplay, unitStyle: useFullUnits ? .full : .short) {
            output.append(minsSeconds)
        }

        if output.isEmpty {
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

    func formatMinsSeconds(mins: Int, secs: Int, unitStyle: DateComponentsFormatter.UnitsStyle = .short) -> String? {
        guard mins > 0 else { return nil }
        let components = DateComponents(calendar: Calendar.current, minute: mins, second: secs)
        return DateComponentsFormatter.localizedString(from: components, unitsStyle: unitStyle)?.replacingOccurrences(of: ",", with: "")
    }
}
