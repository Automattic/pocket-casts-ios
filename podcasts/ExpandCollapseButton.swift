import UIKit

class ExpandCollapseButton: UIButton {
    var expanded = false

    func setExpanded(_ expanded: Bool, animated: Bool = true) {
        self.expanded = expanded
        rotateArrow(down: expanded, animated: animated)
    }

    private func rotateArrow(down: Bool, animated: Bool) {
        let finalRotation = down ? CGFloat(-180).degreesToRadians : CGFloat(0).degreesToRadians

        if animated {
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotateAnimation.duration = Constants.Animation.defaultAnimationTime
            rotateAnimation.repeatCount = 0
            rotateAnimation.isRemovedOnCompletion = false
            rotateAnimation.fillMode = CAMediaTimingFillMode.forwards

            rotateAnimation.fromValue = down ? 0 : CGFloat(-180).degreesToRadians
            rotateAnimation.toValue = finalRotation

            layer.add(rotateAnimation, forKey: "arrowSpin")
        } else {
            transform = CGAffineTransform(rotationAngle: finalRotation)
        }
    }
}
