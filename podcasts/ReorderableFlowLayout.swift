
import Foundation

class ReorderableFlowLayout: UICollectionViewFlowLayout {
    var alphaOnPickup = 0.7 as CGFloat
    var growScale = 1.2 as CGFloat
    var growOffset = 0 as CGFloat

    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)

        attributes.alpha = alphaOnPickup
        if growOffset != 0 {
            attributes.transform = CGAffineTransform(translationX: 0, y: growOffset).scaledBy(x: growScale, y: growScale)
        } else {
            attributes.transform = CGAffineTransform(scaleX: growScale, y: growScale)
        }

        return attributes
    }
}
