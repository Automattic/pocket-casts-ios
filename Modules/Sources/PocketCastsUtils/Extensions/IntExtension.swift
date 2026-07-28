import Foundation

public extension Int {
    init(safeDouble: Double) {
        var valueToConvert = safeDouble
        if valueToConvert > Double(Int.max) {
            valueToConvert = 0
        }

        self.init(valueToConvert)
    }
}
