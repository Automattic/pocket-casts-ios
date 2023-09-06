import UIKit

class MiniPlayerToFullPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let fromViewController: UIViewController
    private let toViewController: UIViewController
    private let transition: Transition

    init?(fromViewController: UIViewController, toViewController: UIViewController, transition: Transition) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.transition = transition
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        3.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let toView = toViewController.view else {
            transitionContext.completeTransition(false)
            return
        }

        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toViewController.view.setNeedsLayout()
        toViewController.view.layoutIfNeeded()

        transitionContext.completeTransition(true)
    }

    enum Transition {
        case presenting
        case dismissing
    }
}
