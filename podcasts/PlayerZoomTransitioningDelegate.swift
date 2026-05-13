import UIKit

@available(iOS 26, *)
final class PlayerZoomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let miniPlayerProvider: () -> MiniPlayerViewController?

    init(miniPlayerProvider: @escaping () -> MiniPlayerViewController?) {
        self.miniPlayerProvider = miniPlayerProvider
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = presented as? PlayerContainerViewController else {
            return nil
        }
        return PlayerZoomAnimator(isPresenting: true, fullPlayer: fullPlayer, miniPlayerProvider: miniPlayerProvider)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = dismissed as? PlayerContainerViewController else {
            return nil
        }
        return PlayerZoomAnimator(isPresenting: false, fullPlayer: fullPlayer, miniPlayerProvider: miniPlayerProvider)
    }
}

@available(iOS 26, *)
final class PlayerZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let fullPlayer: PlayerContainerViewController
    let miniPlayerProvider: () -> MiniPlayerViewController?
    /// Vertical velocity (pts/s) carried from the gesture that triggered the
    /// transition. Non-zero means the user flicked — the animator shortens
    /// the duration, lowers the spring damping, and seeds an initial spring
    /// velocity so the motion picks up where the gesture left off.
    let interactiveVelocity: CGFloat

    private var isInteractive: Bool { interactiveVelocity != 0 }

    private var presentDuration: TimeInterval { isInteractive ? 0.46 : 0.5 }
    private var dismissDuration: TimeInterval { isInteractive ? 0.42 : 0.45 }
    private var presentDamping: CGFloat { isInteractive ? 0.8 : 1.0 }
    private var dismissDamping: CGFloat { isInteractive ? 0.8 : 0.95 }

    /// iOS 26 modal-sheet large corner radius. Matches the device display radius
    /// closely enough on modern iPhones that the full player corners read as
    /// continuous with the screen edges.
    private let finalCornerRadius: CGFloat = 55

    /// Keeps the live mini-player clone alive for the duration of the
    /// transition. The clone is a real `MiniPlayerViewController` view (see
    /// `makeMiniSnapshot`), so its view controller has to be retained until
    /// the animation completes and the view is removed.
    private var miniSnapshotController: MiniPlayerViewController?

    init(
        isPresenting: Bool,
        fullPlayer: PlayerContainerViewController,
        miniPlayerProvider: @escaping () -> MiniPlayerViewController?,
        interactiveVelocity: CGFloat = 0
    ) {
        self.isPresenting = isPresenting
        self.fullPlayer = fullPlayer
        self.miniPlayerProvider = miniPlayerProvider
        self.interactiveVelocity = interactiveVelocity
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? presentDuration : dismissDuration
    }

    /// UIKit's spring velocity is normalized to the animation distance. The
    /// panel's vertical travel (≈ `miniFrame.minY`) is the most visible motion,
    /// so use it as the reference and clamp the result to keep very fast flicks
    /// from overshooting wildly.
    private func initialSpringVelocity(miniFrame: CGRect) -> CGFloat {
        guard isInteractive else { return 0 }
        let travel = max(miniFrame.minY, 1)
        return min(abs(interactiveVelocity) / travel, 6)
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresent(context: context)
        } else {
            animateDismiss(context: context)
        }
    }

    // MARK: - Present

    private func animatePresent(context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        let toVC = fullPlayer
        guard let miniVC = miniPlayerProvider() else {
            context.completeTransition(false)
            return
        }

        toVC.loadViewIfNeeded()
        let toView = toVC.view!
        // toView.alpha was already set to 0 in the transition delegate, so
        // any pre-positioning UIKit did before this point isn't visible.

        let mini = miniVC.view!
        let miniArtwork = miniVC.podcastArtwork!
        let toArtwork = toVC.nowPlayingItem.episodeImage!

        let finalFrame = context.finalFrame(for: toVC)
        let miniFrame = mini.convert(mini.bounds, to: container)
        let miniCornerRadius = miniPillCornerRadius(for: miniFrame)
        let sourceArtFrame = miniArtwork.convert(miniArtwork.bounds, to: container)
        let isMiniInline = mini.traitCollection.tabAccessoryEnvironment == .inline

        // Use alpha (not isHidden) on the artwork views — `toArtwork` is an
        // arranged subview of a UIStackView, and `isHidden = true` would
        // collapse its slot and re-flow the layout, parking the artwork at
        // a degenerate frame. Alpha hides it without affecting the layout.
        miniArtwork.alpha = 0
        toArtwork.alpha = 0
        mini.isHidden = true

        // Lay out toView at its final frame so we can read the destination
        // artwork frame from its final layout. `viewDidLayoutSubviews` on
        // `PlayerContainerViewController` adjusts `headerHeightConstraint`
        // during the first pass (only when `view.window` is non-nil), which
        // dirties the layout — so the artwork frame has to be read after a
        // second pass settles the post-adjustment positions.
        toView.frame = finalFrame
        if toView.superview !== container {
            container.addSubview(toView)
        }
        toView.setNeedsLayout()
        toView.layoutIfNeeded()
        toView.setNeedsLayout()
        toView.layoutIfNeeded()
        let destArtFrameInToView = toVC.computedArtworkFrame()
        // toView ends up at `finalFrame` in container during the final state,
        // so the artwork's final container-space rect is just the in-toView
        // rect offset by finalFrame.origin (typically (0, 0)).
        let destArtFrame = destArtFrameInToView.offsetBy(dx: finalFrame.origin.x, dy: finalFrame.origin.y)

        // Header sits at the top of toView, which is the area visible through
        // the small panel at the start of the transition. Hide it now and fade
        // it back in partway through, once the panel has grown enough that the
        // header doesn't pop in awkwardly.
        toVC.setPlayerHeaderHidden(true, animated: false)
        toVC.setPlayerHeaderHidden(false, animated: true, delay: presentDuration * 0.4)

        // Give toView the final corner radius now so the rounded corners persist
        // after the panel is removed at the end of the transition.
        toView.layer.cornerRadius = finalCornerRadius
        toView.layer.cornerCurve = .continuous
        toView.clipsToBounds = true

        // The player's chrome is painted by `nowPlayingItem.view` (a subview
        // of `toView`), so clearing `toView.backgroundColor` doesn't make the
        // panel see-through. Pull the panel color from that subview so the
        // glass→color morph lands on the real player background.
        let panelColor = toVC.nowPlayingItem.view.backgroundColor
            ?? PlayerColorHelper.playerBackgroundColor01()
        let panel = makePanel(
            frame: miniFrame,
            cornerRadius: miniCornerRadius,
            color: panelColor,
            colorAlpha: 0
        )
        container.addSubview(panel.view)

        // Re-parent toView into the panel. toView is positioned so its left
        // edge sits at the same screen x it will at full size; the panel's
        // clipping crops everything outside the small pill.
        toView.frame = CGRect(x: -miniFrame.minX, y: 0, width: finalFrame.width, height: finalFrame.height)
        panel.view.addSubview(toView)

        let miniSnapshot = makeMiniSnapshot(frame: miniFrame, cornerRadius: miniCornerRadius, isInline: isMiniInline)
        container.addSubview(miniSnapshot)

        let floating = makeFloatingArtwork(
            image: toArtwork.image ?? miniArtwork.imageView?.image,
            frame: sourceArtFrame,
            cornerRadius: miniArtwork.layer.cornerRadius
        )
        container.addSubview(floating)

        // Bring toView in over the back half of the present, so the panel
        // can establish the glass→color morph before the player content
        // resolves. Without this fade the player paints solidly from frame
        // zero — toView's root background is clear, but its subviews aren't.
        UIView.animate(withDuration: presentDuration * 0.55,
                       delay: presentDuration * 0.35,
                       options: [.curveEaseOut]) {
            toView.alpha = 1
        }

        UIView.animate(
            withDuration: presentDuration,
            delay: 0,
            usingSpringWithDamping: presentDamping,
            initialSpringVelocity: initialSpringVelocity(miniFrame: miniFrame),
            options: [.curveEaseInOut]
        ) {
            panel.view.frame = container.bounds
            panel.view.layer.cornerRadius = self.finalCornerRadius
            toView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating.frame = destArtFrame
            floating.layer.cornerRadius = toArtwork.layer.cornerRadius
            panel.colorOverlay.alpha = 1
            // Mini chrome rides up pinned to the panel's top edge and fades out
            // over the full duration, so it animates the whole way rather than
            // vanishing in the first frames.
            miniSnapshot.frame.origin.y = 0
            miniSnapshot.alpha = 0
        } completion: { _ in
            container.addSubview(toView)
            toView.frame = finalFrame
            toView.alpha = 1
            panel.view.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            floating.removeFromSuperview()
            self.miniSnapshotController = nil
            mini.isHidden = false
            miniArtwork.alpha = 1
            toArtwork.alpha = 1
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Dismiss

    private func animateDismiss(context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        let fromVC = fullPlayer
        guard let miniVC = miniPlayerProvider() else {
            context.completeTransition(false)
            return
        }

        let mini = miniVC.view!
        let miniArtwork = miniVC.podcastArtwork!
        let fromArtwork = fromVC.nowPlayingItem.episodeImage!

        let fromView = fromVC.view!
        let finalFrame = fromView.frame
        // If the user dragged the player down before releasing, fromView's
        // origin.y holds that offset. Start the panel at that offset so the
        // dismiss animation picks up where the gesture left off instead of
        // snapping back to y=0.
        let dragOffset = max(0, fromView.frame.origin.y)
        let miniFrame = mini.convert(mini.bounds, to: container)
        let miniCornerRadius = miniPillCornerRadius(for: miniFrame)
        let sourceArtFrame = container.convert(fromVC.computedArtworkFrame(), from: fromView)
        let destArtFrame = miniArtwork.convert(miniArtwork.bounds, to: container)
        let isMiniInline = mini.traitCollection.tabAccessoryEnvironment == .inline

        miniArtwork.alpha = 0
        fromArtwork.alpha = 0
        mini.isHidden = true

        // The panel handles outer clipping with the iOS 26 corner radius, so
        // remove the corner radius from fromView to avoid double-clipping.
        fromView.layer.cornerRadius = 0
        fromView.clipsToBounds = false

        let panelColor = fromVC.nowPlayingItem.view.backgroundColor
            ?? PlayerColorHelper.playerBackgroundColor01()
        let panel = makePanel(
            frame: CGRect(x: 0, y: dragOffset, width: container.bounds.width, height: container.bounds.height),
            cornerRadius: finalCornerRadius,
            color: panelColor,
            colorAlpha: 1
        )
        container.insertSubview(panel.view, belowSubview: fromView)

        fromView.removeFromSuperview()
        fromView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
        panel.view.addSubview(fromView)

        let miniSnapshot = makeMiniSnapshot(
            frame: CGRect(x: miniFrame.minX, y: 0, width: miniFrame.width, height: miniFrame.height),
            cornerRadius: miniCornerRadius,
            isInline: isMiniInline
        )
        miniSnapshot.alpha = 0
        container.addSubview(miniSnapshot)

        let floating = makeFloatingArtwork(
            image: fromArtwork.image ?? miniArtwork.imageView?.image,
            frame: sourceArtFrame,
            cornerRadius: fromArtwork.layer.cornerRadius
        )
        container.addSubview(floating)

        // Fade the full-player contents out faster than the panel shrinks, so
        // the title / controls don't visibly squish during the descent. The
        // floating artwork keeps morphing in its own animation.
        UIView.animate(withDuration: dismissDuration * 0.45, delay: 0, options: [.curveEaseOut]) {
            fromView.alpha = 0
        }

        // Show the mini player instantly so there is a shadow around it
        mini.isHidden = false

        UIView.animate(
            withDuration: dismissDuration,
            delay: 0,
            usingSpringWithDamping: dismissDamping,
            initialSpringVelocity: initialSpringVelocity(miniFrame: miniFrame),
            options: [.curveEaseInOut]
        ) {
            panel.view.frame = miniFrame
            panel.view.layer.cornerRadius = miniCornerRadius
            fromView.frame = CGRect(x: -miniFrame.minX, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating.frame = destArtFrame
            floating.layer.cornerRadius = miniArtwork.layer.cornerRadius
            panel.colorOverlay.alpha = 0
            // Mini chrome rides down from the top, pinned to the panel's top
            // edge, fading in over the full duration so it materializes during
            // the descent instead of popping in at the end.
            miniSnapshot.frame.origin.y = miniFrame.minY
            miniSnapshot.alpha = 1
        } completion: { _ in
            panel.view.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            floating.removeFromSuperview()
            self.miniSnapshotController = nil
            fromArtwork.alpha = 1
            miniVC.resetScrollingTitleAnimation()
            miniArtwork.alpha = 1
            fromView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Builders

    private struct Panel {
        let view: UIView
        let colorOverlay: UIView
    }

    /// Clipping container with a glass backdrop and a color overlay on top.
    /// Animating `colorOverlay.alpha` cross-fades between the glass look (mini
    /// pill) and the opaque full-player background.
    private func makePanel(frame: CGRect, cornerRadius: CGFloat, color: UIColor, colorAlpha: CGFloat) -> Panel {
        let panel = UIView(frame: frame)
        panel.backgroundColor = .clear
        panel.layer.cornerRadius = cornerRadius
        panel.layer.cornerCurve = .continuous
        panel.layer.masksToBounds = true
        panel.clipsToBounds = true

        let glassView = UIVisualEffectView(effect: UIGlassEffect())
        glassView.frame = panel.bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        panel.addSubview(glassView)

        let colorOverlay = UIView(frame: panel.bounds)
        colorOverlay.backgroundColor = color
        colorOverlay.alpha = colorAlpha
        colorOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorOverlay.isUserInteractionEnabled = false
        panel.addSubview(colorOverlay)

        return Panel(view: panel, colorOverlay: colorOverlay)
    }

    /// Empty view that only contributes a CALayer drop shadow — approximates
    /// the UITabAccessory glass shadow during the dismiss so the descending
    /// pill carries a shadow throughout, rather than popping in at the end.
    private func makeShadowHost(frame: CGRect, cornerRadius: CGFloat) -> UIView {
        let view = UIView(frame: frame)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.18
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: frame.size),
            cornerRadius: cornerRadius
        ).cgPath
        return view
    }

    /// Builds a live `MiniPlayerViewController` clone instead of a bitmap
    /// snapshot. Snapshot APIs (`snapshotView`, `drawHierarchy`,
    /// `layer.render`) all produced partial renders for the mini player inside
    /// `UITabAccessory` — labels and stack-view buttons dropped out. A real
    /// view hierarchy renders reliably and animates the same way.
    private func makeMiniSnapshot(frame: CGRect, cornerRadius: CGFloat, isInline: Bool) -> UIView {
        let clone = MiniPlayerViewController()
        clone.loadViewIfNeeded()
        // The clone isn't hosted in a `UITabAccessory`, so its
        // `tabAccessoryEnvironment` trait stays at the default — force the
        // layout flavor that matches the live mini player.
        clone.setForcedInlineLayout(isInline)
        clone.podcastArtwork.isHidden = true
        let cloneView = clone.view!
        cloneView.isUserInteractionEnabled = false
        cloneView.frame = frame
        cloneView.layer.cornerRadius = cornerRadius
        cloneView.layer.cornerCurve = .continuous
        cloneView.clipsToBounds = true
        cloneView.layoutIfNeeded()
        miniSnapshotController = clone
        return cloneView
    }

    private func makeFloatingArtwork(image: UIImage?, frame: CGRect, cornerRadius: CGFloat) -> UIImageView {
        let v = UIImageView(image: image)
        v.frame = frame
        v.contentMode = .scaleAspectFill
        v.layer.cornerRadius = cornerRadius
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        v.isUserInteractionEnabled = false
        return v
    }

    /// The mini player lives inside a `UITabAccessory` pill — approximate its
    /// corner radius as half the height, clamped to a reasonable maximum.
    private func miniPillCornerRadius(for frame: CGRect) -> CGFloat {
        min(frame.height / 2, 30)
    }
}

// MARK: - Helpers on the player view controllers

@available(iOS 26, *)
extension PlayerContainerViewController {
    /// Artwork frame expressed in the player container view's coordinate
    /// space — used as the morph target for the floating artwork during the
    /// zoom transition.
    fileprivate func computedArtworkFrame() -> CGRect {
        let image = nowPlayingItem.episodeImage!
        return image.convert(image.bounds, to: view)
    }

    /// Toggles the player header (close button, up next, tabs row) so the
    /// transition can fade it back in after the panel has grown past the
    /// header's frame.
    fileprivate func setPlayerHeaderHidden(_ hidden: Bool, animated: Bool, delay: TimeInterval = 0) {
        let target: CGFloat = hidden ? 0 : 1
        guard animated else {
            headerView.alpha = target
            return
        }
        UIView.animate(withDuration: 0.25, delay: delay, options: [.curveEaseInOut]) {
            self.headerView.alpha = target
        }
    }
}
