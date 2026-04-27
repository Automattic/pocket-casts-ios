import UIKit

@available(iOS 26.0, *)
class LiquidGlassPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let fromViewController: UIViewController
    private let toViewController: UIViewController
    private let transition: MiniPlayerToFullPlayerAnimator.Transition

    private let miniPlayerArtwork: PodcastImageView
    private let fullPlayerArtwork: UIImageView

    private let dismissVelocity: CGFloat
    private let fullPlayerYPosition: CGFloat

    private lazy var springVelocity: CGFloat = {
        let miniplayerFrame = fromViewController.view.superview?.convert(fromViewController.view.frame, to: nil) ?? .zero
        let distance = miniplayerFrame.origin.y - fullPlayerYPosition
        guard distance > 0 else { return 0 }
        return dismissVelocity / distance
    }()

    private var duration: TimeInterval {
        guard !isPresenting || dismissVelocity != 0 else {
            return 0.3
        }
        return 0.2
    }

    private var isPresenting: Bool {
        transition == .presenting
    }

    private var isVideoPodcast: Bool {
        PlaybackManager.shared.currentEpisode()?.videoPodcast() ?? false
    }

    init?(fromViewController: UIViewController,
          toViewController: UIViewController,
          transition: MiniPlayerToFullPlayerAnimator.Transition,
          miniPlayerArtwork: PodcastImageView,
          fullPlayerArtwork: UIImageView,
          dismissVelocity: CGFloat = 0,
          fullPlayerYPosition: CGFloat = 0) {
        self.fromViewController = fromViewController
        self.toViewController = toViewController
        self.transition = transition
        self.miniPlayerArtwork = miniPlayerArtwork
        self.fullPlayerArtwork = fullPlayerArtwork
        self.dismissVelocity = dismissVelocity
        self.fullPlayerYPosition = fullPlayerYPosition
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard let playerView = toViewController.view else {
            transitionContext.completeTransition(true)
            return
        }

        let onScreenFrame = containerView.frame
        let offScreenFrame = CGRect(x: 0, y: containerView.frame.height,
                                    width: containerView.frame.width,
                                    height: containerView.frame.height)

        // Add the full player at its starting frame and force a layout pass so
        // we can read the artwork's resolved position.
        let startingPlayerFrame = isPresenting ? offScreenFrame : onScreenFrame
        containerView.addSubview(playerView)
        playerView.frame = startingPlayerFrame
        playerView.setNeedsLayout()
        playerView.layoutIfNeeded()

        // Compute the artwork target frame in window coords for the full player
        // at its on-screen position. When presenting, the player is offscreen
        // by containerView.frame.height — back that out.
        var fullPlayerArtworkFrame = fullPlayerArtwork.superview?.convert(fullPlayerArtwork.frame, to: nil) ?? .zero
        if isPresenting {
            fullPlayerArtworkFrame.origin.y -= containerView.frame.height
        }
        let miniPlayerArtworkFrame = miniPlayerArtwork.superview?.convert(miniPlayerArtwork.frame, to: nil) ?? .zero

        var artwork: UIImageView?
        if !isVideoPodcast, fullPlayerArtwork.image != nil {
            fullPlayerArtwork.layer.opacity = 0
            miniPlayerArtwork.layer.opacity = 0

            let imageView = UIImageView()
            imageView.image = fullPlayerArtwork.image
            imageView.contentMode = fullPlayerArtwork.contentMode
            imageView.frame = isPresenting ? miniPlayerArtworkFrame : fullPlayerArtworkFrame
            imageView.layer.cornerRadius = isPresenting ? (miniPlayerArtwork.imageView?.layer.cornerRadius ?? 0) : fullPlayerArtwork.layer.cornerRadius
            imageView.layer.masksToBounds = true
            containerView.addSubview(imageView)
            artwork = imageView
        }

        let miniPlayerView = fromViewController.view
        let restingTransform: CGAffineTransform = .identity
        // Negative y: mini player drops in from above on dismiss (mimicking the
        // full player's downward exit), and lifts upward as it's covered on
        // present (mimicking the full player's upward entry).
        let collapsedTransform = CGAffineTransform(translationX: 0, y: -20).scaledBy(x: 0.92, y: 0.92)
        miniPlayerView?.transform = isPresenting ? restingTransform : collapsedTransform

        animate(withDuration: duration) { [self] in
            playerView.frame = self.isPresenting ? onScreenFrame : offScreenFrame
        } completion: { _ in
            self.fullPlayerArtwork.layer.opacity = !self.isVideoPodcast ? 1 : 0
            self.miniPlayerArtwork.layer.opacity = 1
            artwork?.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        // Artwork morph: smooth ease, no spring overshoot, so the icon doesn't
        // bounce as it lands in its destination.
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            artwork?.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkFrame
            artwork?.layer.cornerRadius = self.isPresenting ? fullPlayerArtwork.layer.cornerRadius : (miniPlayerArtwork.imageView?.layer.cornerRadius ?? 0)
        }

        // Mini player bounce: own spring with low damping so the overshoot reads,
        // and a small delay on dismiss so the bounce isn't hidden behind the
        // descending full player. On present, completion forces back to identity
        // because the mini player is fully covered by then.
        UIView.animate(withDuration: 0.5,
                       delay: isPresenting ? 0 : 0.08,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            miniPlayerView?.transform = self.isPresenting ? collapsedTransform : restingTransform
        } completion: { _ in
            if self.isPresenting {
                miniPlayerView?.transform = .identity
            }
        }
    }

    /// Spring physics matching the legacy animator: dismiss carries gesture
    /// momentum via initialVelocity; present starts from rest.
    private func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        let stiffness: CGFloat = isPresenting ? 400 : 500
        let damping: CGFloat = isPresenting ? 38 : 35
        let velocity = isPresenting ? CGVector.zero : CGVector(dx: 0, dy: springVelocity)
        let timingParameters = UISpringTimingParameters(mass: 1, stiffness: stiffness, damping: damping, initialVelocity: velocity)
        let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingParameters)
        animator.addCompletion { position in
            switch position {
            case .end:
                completion?(true)
            default:
                break
            }
        }
        animator.addAnimations(animations)
        animator.startAnimation()
    }
}
