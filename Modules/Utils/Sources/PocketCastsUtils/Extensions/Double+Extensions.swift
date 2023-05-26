import Foundation

extension Double {

    /// Checks whether the value is not NaN or Infinite
    public var isNumeric: Bool {
        !self.isNaN && !self.isInfinite
    }
}
