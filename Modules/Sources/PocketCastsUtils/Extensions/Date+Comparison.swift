import Foundation

public extension Date {
    func isSameYearAs(_ date: Date) -> Bool {
        let calendar = Calendar.current

        return calendar.component(.year, from: self) == calendar.component(.year, from: date)
    }

    func isCurrentYear() -> Bool {
        let calendar = Calendar.current

        return calendar.component(.year, from: self) == calendar.component(.year, from: Date())
    }
}
