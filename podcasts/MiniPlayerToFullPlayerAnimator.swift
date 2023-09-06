import UIKit

class MiniPlayerToFullPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        3.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        transitionContext.completeTransition(true)
    }
}
