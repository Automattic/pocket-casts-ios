import UIKit

class MiniPlayerToFullPlayerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let fromViewController: UIViewController
    private let toViewController: UIViewController
    private let transition: Transition

    private let miniPlayerArtwork: PodcastImageView
    private let fullPlayerArtwork: UIImageView

    private let dismissVelocity: CGFloat

    private let fullPlayerYPosition: CGFloat

    // Spring velocity is defined by pan gesture velocity / distance.
    // A positive value means moving in the same direction as the animation (downward, toward mini player).
    private lazy var springVelocity: CGFloat = {
        let miniplayerFrame = fromViewController.view.superview?.convert(fromViewController.view.frame, to: nil) ?? .zero
        let distance = miniplayerFrame.origin.y - fullPlayerYPosition
        guard distance > 0 else { return 0 }
        return dismissVelocity / distance
    }()

    // When presenting the player, duration is always the same
    // However, if the view is being dismissed we take into account
    // the velocity of the swipe down gesture to carry it
    // An aggressive swipe down will make the view to be dismissed faster.
    private var duration: TimeInterval {
        guard !isPresenting || dismissVelocity != 0 else {
            return 0.3
        }

        return 0.2
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

        guard let playerView = toViewController.view else {
            transitionContext.completeTransition(true)
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
                fromFrame.origin = .init(x: containerView.frame.origin.x, y: playerView.frame.origin.y)
            }

            return fromFrame
        }()

        /// The player final frame
        let toFrame: CGRect = {
            switch transition {
            case .presenting:
                return containerView.frame
            case .dismissing:
                return fromViewController.view.frame
            }
        }()

        // Add the full player and do a layout pass to avoid issues
        // If presenting, we do this out of the screen to avoid the view briefly appearing
        let playerRenderingFrame = isPresenting ? .init(x: 0, y: 0 + containerView.frame.height, width: containerView.frame.width, height: containerView.frame.height) : fromFrame
        containerView.addSubview(playerView)
        playerView.frame = playerRenderingFrame
        playerView.setNeedsLayout()
        playerView.layoutIfNeeded()

        // Hide artwork in the layer model tree so the snapshot excludes it
        // (the artwork overlay will animate it separately).
        if fullPlayerArtwork.image != nil {
            fullPlayerArtwork.layer.opacity = 0
        }

        // For presenting, capture the full player via drawHierarchy which renders
        // the complete UIKit view hierarchy (including buttons/labels) into an
        // off-screen graphics context — no render-server commit that could flash.
        // For dismissing, skip the player snapshot entirely — the artwork overlay is
        // the visual anchor, and eliminating this render cuts the setup delay.
        let toView: UIView?
        if isPresenting {
            let renderer = UIGraphicsImageRenderer(bounds: playerView.bounds)
            let snapshotImage = renderer.image { _ in
                playerView.drawHierarchy(in: playerView.bounds, afterScreenUpdates: true)
            }
            let imageView = UIImageView(image: snapshotImage)
            imageView.clipsToBounds = true
            toView = imageView
            toView?.frame = containerView.frame
        } else {
            toView = nil
        }

        // MARK: - Artwork

        var miniPlayerArtworkSnapshot: UIView?
        var artwork: UIImageView?

        // Calculate initial and final frame for the artwork
        var fullPlayerArtworkFrame: CGRect = fullPlayerArtwork.superview?.convert(fullPlayerArtwork.frame, to: nil) ?? .zero
        if isPresenting {
            fullPlayerArtworkFrame.origin.y -= containerView.frame.height
        }

        let miniPlayerArtworkFrame = miniPlayerArtwork.superview?.convert(miniPlayerArtwork.frame, to: nil) ?? .zero
        let miniPlayerArtworkWithShadowFrame = miniPlayerArtwork.superview?.superview?.convert(miniPlayerArtwork.superview?.frame ?? .zero, to: nil) ?? .zero

        // Artwork is not animated if it's a video podcast
        if !isVideoPodcast {

            // We need a mini player artwork snapshot when dismissing
            // to ensure a smooth transition and that the shadows are
            // displayed
            miniPlayerArtworkSnapshot = isPresenting ? nil : miniPlayerArtwork.superview?.snapshotView(afterScreenUpdates: false)

            if fullPlayerArtwork.image != nil {
                miniPlayerArtwork.layer.opacity = 0
            }

            if let miniPlayerArtworkSnapshot {
                containerView.addSubview(miniPlayerArtworkSnapshot)
                miniPlayerArtworkSnapshot.frame = isPresenting ? miniPlayerArtworkFrame : fullPlayerArtworkFrame
            }

            artwork = UIImageView()
            artwork?.image = fullPlayerArtwork.image
            artwork?.contentMode = fullPlayerArtwork.contentMode

            containerView.addSubview(artwork ?? UIView())
            artwork?.frame = isPresenting ? miniPlayerArtworkFrame : fullPlayerArtworkFrame
            artwork?.layer.cornerRadius = isPresenting ? miniPlayerArtwork.imageView!.layer.cornerRadius : fullPlayerArtwork.layer.cornerRadius
            artwork?.layer.masksToBounds = true
        }

        // MARK: - Background and Mini Player

        let backgroundTransitionView = MiniPlayerShadowView()

        containerView.addSubview(backgroundTransitionView)
        containerView.sendSubviewToBack(backgroundTransitionView)

        // Get the initial and final colors.
        // Use mainView's background (opaque) rather than the outer view's (.clear)
        // to prevent see-through during the present cross-fade.
        let miniPlayerBackgroundColor = (fromViewController as? MiniPlayerViewController)?.mainView.backgroundColor

        let fullPlayerBackgroundColor = (toViewController as? PlayerContainerViewController)?.nowPlayingItem.view.backgroundColor

        let fromColor = isPresenting ? miniPlayerBackgroundColor : fullPlayerBackgroundColor
        let toColor = isPresenting ? fullPlayerBackgroundColor : miniPlayerBackgroundColor

        let miniPlayerView: UIView = (fromViewController as? MiniPlayerViewController)?.mainView ?? fromViewController.view
        // Get the initial and final frames
        let miniplayerFrame = fromViewController.view.convert(miniPlayerView.frame, to: nil)

        var backgroundTransitionInitialFrame = containerView.frame
        if !isPresenting {
            backgroundTransitionInitialFrame = fromFrame
        }

        let backgroundFromFrame = isPresenting ? miniplayerFrame : backgroundTransitionInitialFrame
        let backgroundToFrame = isPresenting ? toFrame : miniplayerFrame

        // Add a snapshot of the miniplayer and full player.
        // For dismiss, use afterScreenUpdates:false — views are already on screen,
        // and skipping the synchronous render pass reduces the setup delay between
        // gesture end and animation start.
        let miniPlayerSnapshotView = miniPlayerView.snapshotView(afterScreenUpdates: isPresenting)
        miniPlayerSnapshotView?.addSubview(UIVisualEffectView(effect: UIBlurEffect(style: .prominent)))
        miniPlayerSnapshotView?.layer.opacity = isPresenting ? 1 : 0
        backgroundTransitionView.addSubview(toView ?? UIView())
        backgroundTransitionView.addSubview(miniPlayerSnapshotView ?? UIView())
        playerView.isHidden = true

        // MARK: - Tab Bar

        let tabBar = (toViewController.presentingViewController as? MainTabBarController)?.tabBar
        let tabBarSnapshot = tabBar?.snapshotView(afterScreenUpdates: isPresenting)
        tabBar?.isHidden = true
        tabBarSnapshot?.layer.drawTopBorder()
        let snapshotView = tabBarSnapshot ?? UIView()
        containerView.addSubview(snapshotView)
        containerView.sendSubviewToBack(snapshotView)

        // MARK: - Animations

        // Now that playerView is hidden and snapshots/overlays are in place,
        // safely hide the real artwork — no visible flash possible.
        if artwork?.image != nil {
            fullPlayerArtwork.layer.opacity = 0
            miniPlayerArtwork.layer.opacity = 0
        }

        backgroundTransitionView.backgroundColor = fromColor
        backgroundTransitionView.frame = backgroundFromFrame

        toView?.layer.opacity = isPresenting ? 0 : 1
        toView?.frame = .init(x: 0, y: 0, width: fromFrame.width, height: fromFrame.height)

        fromViewController.view.layer.opacity = isPresenting ? 1 : 0

        let tabBarFrame = tabBar?.frame ?? .zero
        let hiddenTabBarFrame = CGRect(x: tabBarFrame.origin.x, y: tabBarFrame.origin.y + tabBarFrame.height, width: tabBarFrame.width, height: tabBarFrame.height)
        tabBarSnapshot?.frame = isPresenting ? tabBarFrame : hiddenTabBarFrame

        let gradientView = MiniPlayerGradientView()
        gradientView.frame = fromViewController.view.frame
        gradientView.layer.opacity = isPresenting ? 1 : 0
        if let miniPlayerVC = fromViewController as? MiniPlayerViewController {
            gradientView.colors = miniPlayerVC.gradientView.colors
        }
        containerView.insertSubview(gradientView, belowSubview: backgroundTransitionView)

        self.fromViewController.view.layer.opacity = 0
        animate(withDuration: duration) { [self] in
            // Artwork
            artwork?.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkFrame
            artwork?.layer.cornerRadius = self.isPresenting ? fullPlayerArtwork.layer.cornerRadius : miniPlayerArtwork.imageView!.layer.cornerRadius


            // snapshot has its frame changed to account for the shadow
            miniPlayerArtworkSnapshot?.frame = self.isPresenting ? fullPlayerArtworkFrame : miniPlayerArtworkWithShadowFrame

            // Background
            backgroundTransitionView.frame = backgroundToFrame
            backgroundTransitionView.backgroundColor = toColor
            backgroundTransitionView.layer.cornerRadius = self.isPresenting ? 0 : miniPlayerView.layer.cornerRadius

            // Miniplayer
            miniPlayerSnapshotView?.layer.opacity = self.isPresenting ? 0 : 1

            // Player
            toView?.layer.opacity = self.isPresenting ? 1 : 0

            // Tab Bar
            tabBarSnapshot?.frame = !self.isPresenting ? tabBarFrame : hiddenTabBarFrame

            gradientView.layer.opacity = isPresenting ? 0 : 1
        } completion: { completed in
            self.fullPlayerArtwork.layer.opacity = !self.isVideoPodcast ? 1 : 0
            self.miniPlayerArtwork.layer.opacity = 1

            artwork?.removeFromSuperview()
            backgroundTransitionView.removeFromSuperview()

            playerView.frame = self.isPresenting ? self.containerView.frame : playerView.frame
            playerView.isHidden = false

            self.fromViewController.view.layer.opacity = 1

            tabBar?.isHidden = false

            transitionContext.completeTransition(true)
        }

        // For presenting, use a separate ease animation for properties
        // that don't need spring physics
        if isPresenting {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                backgroundTransitionView.backgroundColor = toColor
                backgroundTransitionView.layer.cornerRadius = 0
                toView?.layer.opacity = 1
                tabBarSnapshot?.frame = hiddenTabBarFrame
            } completion: { _ in
                tabBar?.isHidden = false
            }
        }
    }

    /// When presenting use curveEaseInOut. If dismissing, use spring animation
    private func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        if isPresenting {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        } else {
            // stiffness 500 → snappy response; damping 35 → ζ ≈ 0.78 (subtle bounce).
            // initialVelocity carries the drag momentum directly into the spring.
            let timingParameters = UISpringTimingParameters(mass: 1, stiffness: 500, damping: 35, initialVelocity: CGVector(dx: 0, dy: springVelocity))
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
