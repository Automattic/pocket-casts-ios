import Foundation

public extension Comparable {
    func clamped(to limits: Range<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
