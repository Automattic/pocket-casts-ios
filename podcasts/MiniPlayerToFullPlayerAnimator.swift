import UIKit

class MiniPlayerToFullPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let fromViewController: UIViewController
    private let toViewController: UIViewController
    private let transition: Transition

    private let miniPlayerArtwork: PodcastImageView
    private let fullPlayerArtwork: UIImageView

    private var duration: TimeInterval = 0.35

    // Initialize with an empty UIView to avoid optional code
    private var containerView = UIView()
    private var toView = UIView()

    init?(fromViewController: UIViewController, toViewController: UIViewController, transition: Transition, miniPlayerArtwork: PodcastImageView, fullPlayerArtwork: UIImageView) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.transition = transition
        self.miniPlayerArtwork = miniPlayerArtwork
        self.fullPlayerArtwork = fullPlayerArtwork
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        containerView = transitionContext.containerView

        guard let toView = toViewController.view else {
            transitionContext.completeTransition(false)
            return
        }

        /// The player initial frame
        var fromFrame: CGRect = {
            var fromFrame: CGRect

            switch transition {
            case .presenting:
                fromFrame = containerView.frame
                fromFrame.origin = .init(x: containerView.frame.origin.x, y: toView.frame.height)
            case .dismissing:
                fromFrame = containerView.frame
                fromFrame.origin = .init(x: containerView.frame.origin.x, y: toView.frame.origin.y)
            }

            return fromFrame
        }()

        /// The player final frame
        var toFrame: CGRect = {
            switch transition {
            case .presenting:
                return containerView.frame
            case .dismissing:
                var toFrame = containerView.frame
                toFrame.origin = .init(x: containerView.frame.origin.x, y: toView.frame.height)
                return toFrame
            }
        }()

        // Add the full player and do a layout pass to avoid issues
        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toViewController.view.setNeedsLayout()
        toViewController.view.layoutIfNeeded()

        toView.frame = fromFrame

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            toView.frame = toFrame
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }
    }

    enum Transition {
        case presenting
        case dismissing
    }
}
