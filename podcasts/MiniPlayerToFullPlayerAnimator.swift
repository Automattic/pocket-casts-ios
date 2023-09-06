import UIKit

class MiniPlayerToFullPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let fromViewController: UIViewController
    private let toViewController: UIViewController
    private let transition: Transition

    // Initialize with an empty UIView to avoid optional code
    private var containerView = UIView()
    private var toView = UIView()

    private lazy var toFrame: CGRect = {
        switch transition {
        case .presenting:
            return containerView.frame
        case .dismissing:
            var toFrame = containerView.frame
            toFrame.origin = .init(x: containerView.frame.origin.x, y: toView.frame.height)
            return toFrame
        }
    }()

    init?(fromViewController: UIViewController, toViewController: UIViewController, transition: Transition) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.transition = transition
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        3.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        containerView = transitionContext.containerView

        guard let toView = toViewController.view else {
            transitionContext.completeTransition(false)
            return
        }

        self.toView = toView

        // Add the full player and do a layout pass to avoid issues
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
