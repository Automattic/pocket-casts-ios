import Foundation

public extension Date {
    func weeksAgo(_ amountOfWeeks: Int) -> Date {
        let calendar = NSCalendar(identifier: .gregorian)
        
        var components = DateComponents()
        components.weekOfYear = amountOfWeeks * -1
        
        let date = calendar?.date(byAdding: components, to: self, options: [])
        
        return date!
    }
}
