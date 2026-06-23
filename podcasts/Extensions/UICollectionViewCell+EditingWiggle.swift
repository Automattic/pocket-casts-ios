import UIKit

extension UICollectionViewCell {
    private static let editingWiggleAnimationKey = "editingWiggle"

    /// Adds a looping wiggle that signals the cell can be dragged to reorder while a grid is in
    /// edit mode. The start time is randomised so cells don't all wiggle in unison. No-op if the
    /// wiggle is already running, so it's safe to call on reused/recycled cells.
    func startEditingWiggle() {
        guard layer.animation(forKey: Self.editingWiggleAnimationKey) == nil else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [-0.012, 0.012, -0.012]
        animation.duration = 0.28
        animation.repeatCount = .infinity
        animation.timeOffset = .random(in: 0...animation.duration)
        layer.add(animation, forKey: Self.editingWiggleAnimationKey)
    }

    func stopEditingWiggle() {
        layer.removeAnimation(forKey: Self.editingWiggleAnimationKey)
    }
}
