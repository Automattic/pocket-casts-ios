import UIKit

/// A button whose tappable area is expanded to a minimum size, centered on its
/// bounds, without affecting its visible layout. Useful for small icon buttons
/// that need to meet Apple's recommended 44x44pt minimum tap target.
final class HitTargetButton: UIButton {
    var minimumHitTarget = CGSize(width: 44, height: 44)

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let dx = min(0, (bounds.width - minimumHitTarget.width) / 2)
        let dy = min(0, (bounds.height - minimumHitTarget.height) / 2)
        return bounds.insetBy(dx: dx, dy: dy).contains(point)
    }
}
