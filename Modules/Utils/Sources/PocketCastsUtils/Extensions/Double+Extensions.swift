import Foundation

extension Double {

    /// Checks whether the value is not NaN or Infinite
    public var isValid: Bool {
        !self.isNaN && !self.isInfinite
    }
}
