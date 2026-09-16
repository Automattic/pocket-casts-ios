import Foundation

public extension Date {
    func isCurrentYear() -> Bool {
        let calendar = Calendar.current

        return calendar.component(.year, from: self) == calendar.component(.year, from: Date())
    }
}
