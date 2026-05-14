import UIKit

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

    private var presentDuration: TimeInterval { isInteractive ? 0.45 : 0.5 }
    private var dismissDuration: TimeInterval { isInteractive ? 0.4 : 0.5 }
    private var presentDamping: CGFloat { isInteractive ? 0.9 : 1.0 }
    private var dismissDamping: CGFloat { isInteractive ? 0.85 : 1.0 }

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

        // Hide the real mini player's controls during the transition so they
        // don't show through the panel's glass material — the `miniSnapshot`
        // clone takes over the visual role until the animation completes.
        // Set alpha on each subview rather than `mini.alpha` so the mini
        // view itself stays in place inside the tab accessory; only its
        // contents are blanked.
        mini.subviews.forEach { $0.alpha = 0 }

        // Use alpha (not isHidden) on `toArtwork` — it's an arranged subview
        // of a UIStackView, and `isHidden = true` would collapse its slot
        // and re-flow the layout, parking the artwork at a degenerate frame.
        toArtwork.alpha = 0

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
        toVC.setPlayerHeaderHidden(false, animated: true, delay: presentDuration * 0.35)

        // Give toView the final corner radius now so the rounded corners persist
        // after the panel is removed at the end of the transition.
        toView.layer.cornerRadius = finalCornerRadius
        toView.layer.cornerCurve = .continuous
        toView.clipsToBounds = true

        // Panel starts as glass (matching the tab accessory) and the
        // full-player color overlay fades in over the transition so the pill
        // morphs from mini-like to full-player rather than staying glass
        // throughout. `nowPlayingItem.view` paints the real player chrome,
        // so use its `backgroundColor` as the source of the full color.
        let fullPlayerColor = toVC.nowPlayingItem.view.backgroundColor
            ?? PlayerColorHelper.playerBackgroundColor01()
        let panel = makePanel(frame: miniFrame, cornerRadius: miniCornerRadius)
        container.addSubview(panel)

        let colorOverlay = addColorOverlay(to: panel, color: fullPlayerColor, alpha: 0)

        // Re-parent toView into the panel. toView is positioned so its left
        // edge sits at the same screen x it will at full size; the panel's
        // clipping crops everything outside the small pill.
        toView.frame = CGRect(x: -miniFrame.minX, y: 0, width: finalFrame.width, height: finalFrame.height)
        panel.addSubview(toView)

        let miniSnapshot = makeMiniSnapshot(frame: miniFrame, cornerRadius: miniCornerRadius, isInline: isMiniInline)
        container.addSubview(miniSnapshot)
        miniSnapshotController?.synchronizeScrollingTitleAnimation(with: miniVC)

        let floating = makeFloatingArtwork(
            image: toArtwork.image ?? miniArtwork.imageView?.image,
            frame: sourceArtFrame,
            cornerRadius: miniArtwork.layer.cornerRadius
        )
        container.addSubview(floating)

        // Fade toView in partway through so the player content doesn't
        // paint solidly from frame zero — toView's root background is clear,
        // but its subviews aren't. Starting too late makes the controls feel
        // like they pop in near the end of the transition.
        UIView.animate(withDuration: presentDuration * 0.5,
                       delay: presentDuration * 0.2,
                       options: [.curveEaseOut]) {
            toView.alpha = 1
            colorOverlay.alpha = 1
        }

        UIView.animate(
            withDuration: presentDuration,
            delay: 0,
            usingSpringWithDamping: presentDamping,
            initialSpringVelocity: initialSpringVelocity(miniFrame: miniFrame),
            options: [.curveEaseInOut]
        ) {
            panel.frame = container.bounds
            panel.layer.cornerRadius = self.finalCornerRadius
            toView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating.frame = destArtFrame
            floating.layer.cornerRadius = toArtwork.layer.cornerRadius
            // Mini chrome rides up pinned to the panel's top edge and fades out
            // over the full duration, so it animates the whole way rather than
            // vanishing in the first frames.
            miniSnapshot.frame.origin.y = 0
            miniSnapshot.alpha = 0
            mini.alpha = 0.2 // Can't hide it completely as it breaks the shadows
        } completion: { _ in
            container.addSubview(toView)
            toView.frame = finalFrame
            toView.alpha = 1
            panel.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            floating.removeFromSuperview()
            self.miniSnapshotController = nil
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
        let destArtFrame = miniArtwork.convert(miniArtwork.bounds, to: container)
        // The full-player artwork only lives on the Now Playing tab — the
        // other tabs scroll `nowPlayingItem` horizontally off-screen inside
        // `mainScrollView`, so the converted artwork frame lands far to the
        // left and the floating image is never visible during the dismiss.
        // Anchor the floating artwork to the mini snapshot's artwork slot
        // instead so it rides down with the descending panel and lands in
        // the right place.
        let isOnNowPlaying = fromVC.tabsView.currentTab == 0
        let sourceArtFrame: CGRect
        let sourceArtCornerRadius: CGFloat
        if isOnNowPlaying {
            sourceArtFrame = container.convert(fromVC.computedArtworkFrame(), from: fromView)
            sourceArtCornerRadius = fromArtwork.layer.cornerRadius
        } else {
            let artOffsetInMini = CGPoint(x: destArtFrame.minX - miniFrame.minX,
                                          y: destArtFrame.minY - miniFrame.minY)
            sourceArtFrame = CGRect(x: miniFrame.minX + artOffsetInMini.x,
                                    y: artOffsetInMini.y,
                                    width: destArtFrame.width,
                                    height: destArtFrame.height)
            sourceArtCornerRadius = miniArtwork.layer.cornerRadius
        }
        let isMiniInline = mini.traitCollection.tabAccessoryEnvironment == .inline

        miniArtwork.alpha = 0
        fromArtwork.alpha = 0

        // The panel handles outer clipping with the iOS 26 corner radius, so
        // remove the corner radius from fromView to avoid double-clipping.
        fromView.layer.cornerRadius = 0
        fromView.clipsToBounds = false

        let fullPlayerColor = fromVC.nowPlayingItem.view.backgroundColor
            ?? PlayerColorHelper.playerBackgroundColor01()
        let panel = makePanel(
            frame: CGRect(x: 0, y: dragOffset, width: container.bounds.width, height: container.bounds.height),
            cornerRadius: finalCornerRadius
        )
        container.insertSubview(panel, belowSubview: fromView)

        let colorOverlay = addColorOverlay(to: panel, color: fullPlayerColor, alpha: 1)

        fromView.removeFromSuperview()
        fromView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
        panel.addSubview(fromView)

        let miniSnapshot = makeMiniSnapshot(
            frame: CGRect(x: miniFrame.minX, y: dragOffset, width: miniFrame.width, height: miniFrame.height),
            cornerRadius: miniCornerRadius,
            isInline: isMiniInline
        )
        miniSnapshot.alpha = 0
        container.addSubview(miniSnapshot)
        miniSnapshotController?.synchronizeScrollingTitleAnimation(with: miniVC)

        let floating = makeFloatingArtwork(
            image: fromArtwork.image ?? miniArtwork.imageView?.image,
            frame: sourceArtFrame,
            cornerRadius: sourceArtCornerRadius
        )
        container.addSubview(floating)

        // Fade the full-player contents out faster than the panel shrinks, so
        // the title / controls don't visibly squish during the descent. The
        // floating artwork keeps morphing in its own animation.
        UIView.animate(withDuration: dismissDuration * 0.45, delay: 0, options: [.curveEaseOut]) {
            fromView.alpha = 0
            colorOverlay.alpha = 0
            miniSnapshot.alpha = 1
        }

        UIView.animate(withDuration: dismissDuration * 0.35, delay: dismissDuration * 0.55, options: [.curveEaseOut]) {
            mini.alpha = 1 // Restore slightly earlier that controls so shadows are in place
        }

        UIView.animate(
            withDuration: dismissDuration,
            delay: 0,
            usingSpringWithDamping: dismissDamping,
            initialSpringVelocity: initialSpringVelocity(miniFrame: miniFrame),
            options: [.curveEaseInOut]
        ) {
            panel.frame = miniFrame
            panel.layer.cornerRadius = miniCornerRadius
            fromView.frame = CGRect(x: -miniFrame.minX, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating.frame = destArtFrame
            floating.layer.cornerRadius = miniArtwork.layer.cornerRadius
            // Mini chrome rides down from the top, pinned to the panel's top
            // edge, fading in over the full duration so it materializes during
            // the descent instead of popping in at the end.
            miniSnapshot.frame.origin.y = miniFrame.minY
        } completion: { _ in
            panel.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            mini.subviews.forEach { $0.alpha = 1 }
            floating.removeFromSuperview()
            self.miniSnapshotController = nil
            fromArtwork.alpha = 1
            miniArtwork.alpha = 1
            fromView.removeFromSuperview()
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Builders

    private func makePanel(frame: CGRect, cornerRadius: CGFloat) -> UIView {
        let panel = UIView(frame: frame)
        panel.backgroundColor = .clear
        panel.layer.cornerRadius = cornerRadius
        panel.layer.cornerCurve = .continuous
        panel.layer.masksToBounds = true
        panel.clipsToBounds = true

        // Glass material matching the `UITabAccessory` that hosts the mini
        // player. At the start (panel at miniFrame) this makes the panel
        // visually continuous with the tab accessory; the full-player color
        // overlay fades in on top as the panel expands.
        let blurView = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        blurView.frame = panel.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        panel.addSubview(blurView)

        return panel
    }

    /// Full-width color layer added behind the player content so the panel
    /// can cross-fade between the mini-player color (panel background) and
    /// the full-player color (this overlay) by animating `alpha`.
    private func addColorOverlay(to panel: UIView, color: UIColor, alpha: CGFloat) -> UIView {
        let overlay = UIView(frame: panel.bounds)
        overlay.backgroundColor = color
        overlay.alpha = alpha
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = false
        panel.addSubview(overlay)
        return overlay
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
