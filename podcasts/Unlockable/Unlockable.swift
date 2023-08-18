import Foundation

/// Unlockable Protocol: Represents an item that is connected to a `PaidFeature` and can be unlocked with a subscription tier.
/// Callers can check the `isUnlocked` property to determine whether the user can access it. By default this checked `paidFeature.isUnlocked`
/// but can be customized to suit each options needs.
protocol Unlockable {
    /// Whether the feature is unlocked
    var isUnlocked: Bool { get }

    /// Returns the `PaidFeature` that the locked item is tied to
    var paidFeature: PaidFeature? { get }
}

/// Provides the default isUnlocked functionality
extension Unlockable {
    var isUnlocked: Bool {
        paidFeature?.isUnlocked ?? true
    }
}
