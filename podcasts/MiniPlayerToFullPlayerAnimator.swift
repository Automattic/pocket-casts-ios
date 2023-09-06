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

    private var isPresenting: Bool {
        transition == .presenting
    }

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

        // Calculate initial and final frame for the artwork
        var fullPlayerArtworkFrame: CGRect = {
            var fullPlayerArtworkFrame = fullPlayerArtwork.superview?.convert(fullPlayerArtwork.frame, to: nil) ?? .zero
            if !isPresenting {
                fullPlayerArtworkFrame.origin = .init(x: fullPlayerArtworkFrame.origin.x, y: fullPlayerArtworkFrame.origin.y + fromFrame.origin.y)
            }
            return fullPlayerArtworkFrame
        }()

        var miniPlayerArtworkFrame = miniPlayerArtwork.superview?.convert(miniPlayerArtwork.frame, to: nil) ?? .zero

        toView.frame = fromFrame

        let artwork = UIImageView()
        artwork.image = fullPlayerArtwork.image

        containerView.addSubview(artwork)
        artwork.frame = isPresenting ? miniPlayerArtworkFrame : fullPlayerArtworkFrame
        artwork.layer.cornerRadius = isPresenting ? miniPlayerArtwork.imageView!.layer.cornerRadius : fullPlayerArtwork.layer.cornerRadius
        artwork.layer.masksToBounds = true

        // has image?
        if artwork.image != nil {
            fullPlayerArtwork.layer.opacity = 0
            miniPlayerArtwork.layer.opacity = 0
        }

        UIView.animate(withDuration: isPresenting ? 0.25 : 0.35, delay: isPresenting ? 0.1 : 0, options: .curveEaseInOut) { [self] in
            artwork.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkFrame
            artwork.layer.cornerRadius = self.isPresenting ? fullPlayerArtwork.layer.cornerRadius : miniPlayerArtwork.imageView!.layer.cornerRadius
        } completion: { completed in
            artwork.removeFromSuperview()

            self.fullPlayerArtwork.layer.opacity = 1
            self.miniPlayerArtwork.layer.opacity = 1
        }

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
