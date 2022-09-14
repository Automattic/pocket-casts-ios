import Foundation

extension Date {
    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }

    static var lastMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    }
}
