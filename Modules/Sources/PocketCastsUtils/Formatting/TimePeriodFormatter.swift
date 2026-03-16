import Foundation

public enum TimePeriodFormatter {
    /// Convert a number of units (30) and a calendar period unit (days) into a localized string (30 days)
    /// - Parameters:
    ///   - numberOfUnits: The number of units that you want to convert in int form
    ///   - unit: A supported period unit (.days, .weekOfMonth, .month, .year)
    /// - Returns: A localized formatted string
    public static func format(numberOfUnits: Int, unit: NSCalendar.Unit) -> String? {
        guard let componentUnit = unit.componentUnit() else {
            return nil
        }

        var components = DateComponents()
        components.calendar = Calendar.current
        components.setValue(numberOfUnits, for: componentUnit)

        let dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .full
        dateFormatter.allowedUnits = [unit]

        return dateFormatter.string(from: components)
    }
}

private extension NSCalendar.Unit {
    func componentUnit() -> Calendar.Component? {
        switch self {
        case .day:
            return .day
        case .weekOfMonth:
            return .weekOfMonth
        case .month:
            return .month
        case .year:
            return .year
        default:
            return nil
        }
    }
}
