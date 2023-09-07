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

    private var isVideoPodcast: Bool {
        PlaybackManager.shared.currentEpisode()?.videoPodcast() ?? false
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

        // MARK: - Full Player

        /// The player initial frame
        let fromFrame: CGRect = {
            var fromFrame: CGRect

            switch transition {
            case .presenting:
                fromFrame = containerView.frame
                fromFrame.origin = .init(x: containerView.frame.origin.x, y: fromViewController.view.frame.origin.y)
            case .dismissing:
                fromFrame = containerView.frame
                fromFrame.origin = .init(x: containerView.frame.origin.x, y: toView.frame.origin.y)
            }

            return fromFrame
        }()

        /// The player final frame
        let toFrame: CGRect = {
            switch transition {
            case .presenting:
                return containerView.frame
            case .dismissing:
                var toFrame = containerView.frame
                toFrame.origin = .init(x: containerView.frame.origin.x, y: fromViewController.view.frame.origin.y)
                return toFrame
            }
        }()

        // Add the full player and do a layout pass to avoid issues
        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toViewController.view.setNeedsLayout()
        toViewController.view.layoutIfNeeded()

        // MARK: - Artwork

        // Artwork is not animated if it's a video podcast
        if !isVideoPodcast {

            // Calculate initial and final frame for the artwork
            let fullPlayerArtworkFrame: CGRect = {
                var fullPlayerArtworkFrame = fullPlayerArtwork.superview?.convert(fullPlayerArtwork.frame, to: nil) ?? .zero
                if !isPresenting {
                    fullPlayerArtworkFrame.origin = .init(x: fullPlayerArtworkFrame.origin.x, y: fullPlayerArtworkFrame.origin.y + fromFrame.origin.y)
                }
                return fullPlayerArtworkFrame
            }()

            let miniPlayerArtworkFrame = miniPlayerArtwork.superview?.convert(miniPlayerArtwork.frame, to: nil) ?? .zero

            let artwork = UIImageView()
            artwork.image = fullPlayerArtwork.image

            containerView.addSubview(artwork)
            artwork.frame = isPresenting ? miniPlayerArtworkFrame : fullPlayerArtworkFrame
            artwork.layer.cornerRadius = isPresenting ? miniPlayerArtwork.imageView!.layer.cornerRadius : fullPlayerArtwork.layer.cornerRadius
            artwork.layer.masksToBounds = true

            // If it has artwork, hide the original ones
            if artwork.image != nil {
                fullPlayerArtwork.layer.opacity = 0
                miniPlayerArtwork.layer.opacity = 0
            }

            // MARK: - Artwork animation

            UIView.animate(withDuration: duration, delay: 0, options: isPresenting ? .curveEaseInOut : .curveEaseOut) { [self] in
                artwork.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkFrame
                artwork.layer.cornerRadius = self.isPresenting ? fullPlayerArtwork.layer.cornerRadius : miniPlayerArtwork.imageView!.layer.cornerRadius
            } completion: { completed in
                artwork.removeFromSuperview()

                self.fullPlayerArtwork.layer.opacity = 1
                self.miniPlayerArtwork.layer.opacity = 1
            }

        }

        // MARK: - Player animation

        toView.frame = fromFrame
        toView.layer.opacity = isPresenting ? 0 : 1
        UIView.animate(withDuration: duration, delay: 0, options: isPresenting ? .curveEaseInOut : .curveEaseOut) {
            toView.frame = toFrame
            toView.layer.opacity = self.isPresenting ? 1 : 0
        } completion: { completed in
            transitionContext.completeTransition(completed)
        }

        // MARK: - Background and Mini Player

        let backgroundTransitionView = UIView()
        containerView.addSubview(backgroundTransitionView)
        containerView.sendSubviewToBack(backgroundTransitionView)

        // Get the initial and final colors
        let miniPlayerBackgroundColor = (fromViewController as? MiniPlayerViewController)?.mainView.backgroundColor
        let fullPlayerBackgroundColor = (toViewController as? PlayerContainerViewController)?.nowPlayingItem.view.backgroundColor

        let fromColor = isPresenting ? miniPlayerBackgroundColor : fullPlayerBackgroundColor
        let toColor = isPresenting ? fullPlayerBackgroundColor : miniPlayerBackgroundColor

        // Get the initial and final frames
        let miniplayerFrame = fromViewController.view.superview?.convert(fromViewController.view.frame, to: nil) ?? .zero

        var backgroundTransitionInitialFrame = containerView.frame
        if !isPresenting {
            backgroundTransitionInitialFrame.origin = .init(x: backgroundTransitionInitialFrame.origin.x, y: backgroundTransitionInitialFrame.origin.y + fromFrame.origin.y)
        }

        let backgroundFromFrame = isPresenting ? miniplayerFrame : backgroundTransitionInitialFrame
        let backgroundToFrame = isPresenting ? toFrame : miniplayerFrame

        // Add a snapshot of the miniplayer
        let miniPlayerSnapshotView = fromViewController.view.snapshotView(afterScreenUpdates: true)
        backgroundTransitionView.addSubview(miniPlayerSnapshotView ?? UIView())

        // MARK: - Background animation

        backgroundTransitionView.backgroundColor = fromColor
        backgroundTransitionView.frame = backgroundFromFrame

        UIView.animate(withDuration: duration, delay: 0, options: isPresenting ? .curveEaseInOut : .curveEaseOut) {
            backgroundTransitionView.backgroundColor = toColor
            backgroundTransitionView.frame = backgroundToFrame
        } completion: { completed in
            backgroundTransitionView.removeFromSuperview()
        }

        // MARK: - Mini Player animation

        miniPlayerSnapshotView?.layer.opacity = isPresenting ? 1 : 0
        UIView.animate(withDuration: isPresenting ? 0.1 : duration, delay: 0, options: .curveEaseInOut) {
            miniPlayerSnapshotView?.layer.opacity = self.isPresenting ? 0 : 1
        }
    }

    enum Transition {
        case presenting
        case dismissing
    }
}
