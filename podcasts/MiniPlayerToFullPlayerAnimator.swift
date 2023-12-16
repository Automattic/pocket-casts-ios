import UIKit

class MiniPlayerToFullPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let fromViewController: UIViewController
    private let toViewController: UIViewController
    private let transition: Transition

    private let miniPlayerArtwork: PodcastImageView
    private let fullPlayerArtwork: UIImageView

    private let dismissVelocity: CGFloat

    // The max duration that the transition can last
    private let maxDismissDuration: TimeInterval = 0.2

    // An assumed "normal" velocity from a pan gesture
    private let normalVelocity: CGFloat = 2500

    private let fullPlayerYPosition: CGFloat

    // Spring velocity is defined by pan gesture velocity / distance
    private lazy var springVelocity: CGFloat = {
        let miniplayerFrame = fromViewController.view.superview?.convert(fromViewController.view.frame, to: nil) ?? .zero
        let distance = miniplayerFrame.origin.y - fullPlayerYPosition
        return dismissVelocity / distance
    }()

    // When presenting the player, duration is always the same
    // However, if the view is being dismissed we take into account
    // the velocity of the swipe down gesture to carry it
    // An agressive swipe down will make the view to be dismissed faster.
    private var duration: TimeInterval {
        guard !isPresenting || dismissVelocity != 0 else {
            return 0.3
        }

        return min((normalVelocity * maxDismissDuration) / dismissVelocity, maxDismissDuration)
    }

    // Initialize with an empty UIView to avoid optional code
    private var containerView = UIView()
    private var toView = UIView()

    private var isPresenting: Bool {
        transition == .presenting
    }

    private var isVideoPodcast: Bool {
        PlaybackManager.shared.currentEpisode()?.videoPodcast() ?? false
    }

    init?(fromViewController: UIViewController, toViewController: UIViewController, transition: Transition, miniPlayerArtwork: PodcastImageView, fullPlayerArtwork: UIImageView, dismissVelocity: CGFloat = 0, fullPlayerYPosition: CGFloat = 0) {
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
        containerView = transitionContext.containerView

        guard let toView = toViewController.view else {
            transitionContext.completeTransition(false)
            return
        }

        // MARK: - Mini player artwork + shadow

        let miniPlayerArtworkFrame = miniPlayerArtwork.superview?.convert(miniPlayerArtwork.frame, to: nil) ?? .zero

        // We need a mini player artwork snapshot when dismissing
        // to ensure a smooth transition and that the shadows are
        // displayed
        let miniPlayerArtworkSnapshot: UIView? = {
            guard !isPresenting else {
                return nil
            }

            let toSnapshot = UIView()
            toSnapshot.frame = miniPlayerArtworkFrame
            let coverWithShadow = PodcastImageView()
            coverWithShadow.setImageManually(image: fullPlayerArtwork.image, size: .list)
            toSnapshot.addSubview(coverWithShadow)

            // Padding is added so the shadow appears in the snapshot
            coverWithShadow.anchorToAllSidesOf(view: toSnapshot, padding: 2)

            return toSnapshot.snapshotView(afterScreenUpdates: true)
        }()

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

        // MARK: - Tab bar

        // When dismissing, add the tab bar so the miniplayer appear behind it (not in front)
        if !isPresenting,
           let tabBar = (toViewController.presentingViewController as? MainTabBarController)?.tabBar,
           let tabBarSnapshot = tabBar.snapshotView(afterScreenUpdates: true) {
            tabBarSnapshot.layer.drawTopBorder()
            containerView.addSubview(tabBarSnapshot)
            containerView.sendSubviewToBack(tabBarSnapshot)
            tabBarSnapshot.frame = tabBar.frame
        }

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

            if let miniPlayerArtworkSnapshot {
                containerView.addSubview(miniPlayerArtworkSnapshot)
                miniPlayerArtworkSnapshot.frame = isPresenting ? miniPlayerArtworkFrame : fullPlayerArtworkFrame
            }

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

            // We fade from the big artwork to the miniplayer snapshot to ensure
            // a smooth transition. DispatchQueue is needed because delay conflicts
            // with snapshotView(afterScreenUpdates: true) (yes...)
            if !isPresenting {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: self.duration * 0.3, delay: self.duration * 0.7, options: .curveEaseOut) { [self] in
                        artwork.layer.opacity = self.isPresenting ? 1 : 0
                    }
                }
            }

            animate(withDuration: duration) { [self] in
                artwork.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkFrame
                artwork.layer.cornerRadius = self.isPresenting ? fullPlayerArtwork.layer.cornerRadius : miniPlayerArtwork.imageView!.layer.cornerRadius

                // snapshot has its frame changed to account for the shadow
                miniPlayerArtworkSnapshot?.frame = self.isPresenting ? fullPlayerArtworkFrame : CGRect(x: miniPlayerArtworkFrame.origin.x - 2, y: miniPlayerArtworkFrame.origin.y - 2, width: miniPlayerArtworkFrame.width + 4, height: miniPlayerArtworkFrame.height + 4)
            } completion: { completed in
                artwork.removeFromSuperview()

                self.fullPlayerArtwork.layer.opacity = 1
                self.miniPlayerArtwork.layer.opacity = 1
            }

        }

        // MARK: - Player animation

        toView.frame = fromFrame
        toView.layer.opacity = isPresenting ? 0 : 1
        animate(withDuration: duration) {
            toView.frame = toFrame
            toView.layer.opacity = self.isPresenting ? 1 : 0
        } completion: { completed in
            transitionContext.completeTransition(true)
        }

        // MARK: - Background and Mini Player

        let backgroundTransitionView = MiniPlayerBackingView()
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

        animate(withDuration: duration) {
            backgroundTransitionView.backgroundColor = toColor
            backgroundTransitionView.frame = backgroundToFrame
        } completion: { completed in
            backgroundTransitionView.removeFromSuperview()
        }

        // MARK: - Mini Player animation

        miniPlayerSnapshotView?.layer.opacity = isPresenting ? 1 : 0
        fromViewController.view.layer.opacity = isPresenting ? 1 : 0
        animate(withDuration: duration) {
            miniPlayerSnapshotView?.layer.opacity = self.isPresenting ? 0 : 1
        } completion: { _ in
            self.fromViewController.view.layer.opacity = 1
        }
    }

    /// When presenting use curveEaseInOut. If dismissing, use spring animation
    private func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if isPresenting {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        } else {
            let timingParameters = UISpringTimingParameters(mass: 1, stiffness: 400, damping: 30, initialVelocity: CGVector(dx: 0, dy: abs(springVelocity)))
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

    enum Transition {
        case presenting
        case dismissing
    }
}

extension CALayer {
    func drawTopBorder() {
        let border = CALayer()
        border.frame = CGRect(x: 0, y: 0, width: frame.width, height: 1.0 / UIScreen.main.scale)
        border.backgroundColor = UITabBarAppearance().shadowColor?.cgColor
        addSublayer(border)
    }
}
