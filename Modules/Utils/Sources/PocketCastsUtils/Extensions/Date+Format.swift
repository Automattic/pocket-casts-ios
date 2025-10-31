import Foundation

extension Date {
    public func monthDayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }
}
