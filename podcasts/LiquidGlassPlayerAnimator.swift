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
        if isPresenting {
            return 0.55
        }
        // Dismiss: scale duration with gesture velocity so slow flicks get a
        // longer settle (no rushed feel) while fast flicks finish quickly and
        // keep up with the user's intent.
        return 0.45 - min(0.15, dismissVelocity / 8000)
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

        // Add the full player to the container. On present, place it offscreen
        // and force a layout pass so we can read the artwork's resolved
        // position. On dismiss, leave the frame alone — an interactive gesture
        // may have already moved it, and snapping back to onScreenFrame would
        // jump the player (and the artwork inside it) to the top before
        // animating.
        containerView.addSubview(playerView)
        if isPresenting {
            playerView.frame = offScreenFrame
            playerView.setNeedsLayout()
            playerView.layoutIfNeeded()
        }
        playerView.alpha = 1

        // Compute the artwork frame in window coords. On present, this is the
        // target on-screen position — the player is currently offscreen by
        // containerView.frame.height, so back that out. On dismiss, this is
        // the artwork's actual (possibly gesture-dragged) position, which is
        // exactly where the morph should start from.
        var fullPlayerArtworkFrame = fullPlayerArtwork.superview?.convert(fullPlayerArtwork.frame, to: nil) ?? .zero
        if isPresenting {
            fullPlayerArtworkFrame.origin.y -= containerView.frame.height
        }
        // Use the presentation layer so the source frame reflects the
        // interactive UIGlassEffect press/zoom that's in flight at tap time —
        // the model frame would start the morph from the un-zoomed position.
        let miniPlayerArtworkLayer = miniPlayerArtwork.layer.presentation() ?? miniPlayerArtwork.layer
        let miniPlayerArtworkFrame = miniPlayerArtworkLayer.convert(miniPlayerArtwork.bounds, to: nil)

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
        // Present-end: mini player lifts upward and shrinks slightly as it's
        // covered, mimicking the full player's upward entry.
        let coveredTransform = CGAffineTransform(translationX: 0, y: -20).scaledBy(x: 0.92, y: 0.92)
        // Dismiss-start: mini player begins expanded and offset upward, then
        // springs back to rest — as if absorbing the full player zooming back
        // into it. Paired with a bouncy spring so it settles with overshoot.
        let absorbingTransform = CGAffineTransform(translationX: 0, y: -36).scaledBy(x: 1.12, y: 1.12)
        miniPlayerView?.transform = isPresenting ? restingTransform : absorbingTransform

        animate(withDuration: duration) { [self] in
            playerView.frame = self.isPresenting ? onScreenFrame : offScreenFrame
            // Slight scale-down on dismiss adds an Apple Music-like "lift away"
            // feel; on present we settle back to identity in case anything left
            // a residual transform from a previous dismiss.
            playerView.transform = self.isPresenting ? .identity : CGAffineTransform(scaleX: 0.97, y: 0.97)
            // Subtle fade on dismiss (not all the way to 0) so the seam where
            // the morphing artwork hands back to the mini player is masked
            // without making the player feel like it's vanishing.
            playerView.alpha = self.isPresenting ? 1 : 0.33
            artwork?.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkFrame
            artwork?.layer.cornerRadius = self.isPresenting ? self.fullPlayerArtwork.layer.cornerRadius : (self.miniPlayerArtwork.imageView?.layer.cornerRadius ?? 0)
            // Present-only here — dismiss runs the mini player on a separate
            // bouncier spring below.
            if self.isPresenting {
                miniPlayerView?.transform = coveredTransform
            }
        } completion: { _ in
            self.fullPlayerArtwork.layer.opacity = !self.isVideoPodcast ? 1 : 0
            self.miniPlayerArtwork.layer.opacity = 1
            if self.isPresenting {
                miniPlayerView?.transform = .identity
            }
            artwork?.removeFromSuperview()
            playerView.transform = .identity
            playerView.alpha = 1
            transitionContext.completeTransition(true)
        }

        // Dismiss only: bouncy absorb spring on the mini player itself, so it
        // visibly settles after the full player "collapses" into it.
        if !isPresenting {
            animateMiniPlayerAbsorb {
                miniPlayerView?.transform = restingTransform
            }
        }
    }

    private func animateMiniPlayerAbsorb(animations: @escaping () -> Void) {
        // Higher damping + longer duration trades a sharp wobble for a softer
        // settle — still a visible overshoot, but it eases out instead of
        // bouncing.
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 0.6,
            initialVelocity: CGVector(dx: 0, dy: springVelocity)
        )
        let animator = UIViewPropertyAnimator(duration: duration * 1.75, timingParameters: timingParameters)
        animator.addAnimations(animations)
        animator.startAnimation()
    }

    /// Critically damped spring (no overshoot) used for the main present and
    /// dismiss move. On dismiss, initialVelocity carries the gesture's
    /// momentum into the animation so it doesn't lurch when the user lets go;
    /// on present we start from rest. The mini player's absorb on dismiss uses
    /// a separate bouncier spring — see `animateMiniPlayerAbsorb`.
    private func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        let dampingRatio: CGFloat = 1.0
        let velocity = isPresenting ? CGVector.zero : CGVector(dx: 0, dy: springVelocity)
        let timingParameters = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: velocity)
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
