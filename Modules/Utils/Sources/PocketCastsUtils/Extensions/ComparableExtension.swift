import Foundation

public extension Comparable {
    func clamped(to limits: Range<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }

    func betweenOrClamped(to limits: Range<Self>) -> Self {
        self > limits.lowerBound && self < limits.upperBound ? self : self.clamped(to: limits)
    }
}

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }

    func betweenOrClamped(to limits: ClosedRange<Self>) -> Self {
        self > limits.lowerBound && self < limits.upperBound ? self : self.clamped(to: limits)
    }
}
