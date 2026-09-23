import UIKit

@available(iOS 26, *)
@MainActor
final class PlayerZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let fullPlayer: PlayerContainerViewController
    let miniPlayer: MiniPlayerViewController
    /// Vertical velocity (pts/s) carried from the gesture that triggered the
    /// transition. Non-zero means the user flicked — the animator shortens
    /// the duration, lowers the spring damping, and seeds an initial spring
    /// velocity so the motion picks up where the gesture left off.
    let interactiveVelocity: CGFloat

    private var isInteractive: Bool { interactiveVelocity != 0 }

    private var isVideoShown: Bool {
        PlaybackManager.shared.shouldRenderVideo()
    }

    private var presentDuration: TimeInterval { isInteractive ? 0.45 : 0.5 }
    private var dismissDuration: TimeInterval { isInteractive ? 0.4 : 0.45 }
    private var presentDamping: CGFloat { isInteractive ? 0.9 : 1.0 }
    private var dismissDamping: CGFloat { isInteractive ? 0.85 : 1.0 }

    /// Keeps the live mini-player clone alive for the duration of the
    /// transition. The clone is a real `MiniPlayerViewController` view (see
    /// `makeMiniSnapshot`), so its view controller has to be retained until
    /// the animation completes and the view is removed.
    private var miniSnapshotController: MiniPlayerViewController?

    init(
        isPresenting: Bool,
        fullPlayer: PlayerContainerViewController,
        miniPlayer: MiniPlayerViewController,
        interactiveVelocity: CGFloat = 0
    ) {
        self.isPresenting = isPresenting
        self.fullPlayer = fullPlayer
        self.miniPlayer = miniPlayer
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
        let miniVC = miniPlayer
        // Drop the mini-player handoff artwork for video — otherwise it would
        // be installed on `episodeImage` in `willBeAddedToPlayer` and bleed
        // through the floating video's letterbox bands.
        if isVideoShown {
            toVC.nowPlayingItem.placeholderArtwork = nil
        }
        toVC.loadViewIfNeeded()
        toVC.nowPlayingItem.loadViewIfNeeded()
        miniVC.loadViewIfNeeded()

        guard
            let toView = toVC.viewIfLoaded,
            let mini = miniVC.viewIfLoaded,
            let miniArtwork = miniVC.podcastArtwork,
            let toArtwork = toVC.nowPlayingItem.artworkImageView
        else {
            // This should never happen — fall back to a basic fade-in so the
            // user isn't left stranded.
            guard let toView = toVC.viewIfLoaded else {
                context.completeTransition(false)
                return
            }
            toView.frame = context.finalFrame(for: toVC)
            if toView.superview !== container {
                container.addSubview(toView)
            }
            toView.alpha = 0
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                toView.alpha = 1
            } completion: { _ in
                let didComplete = !context.transitionWasCancelled
                if !didComplete {
                    toView.removeFromSuperview()
                }
                context.completeTransition(didComplete)
            }
            return
        }

        // toView.alpha was already set to 0 in the transition delegate, so
        // any pre-positioning UIKit did before this point isn't visible.

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

        let destArtFrameInToView = toArtwork.convert(toArtwork.bounds, to: toView)
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

        // Round the player's corners to the device's display radius for the
        // morph; the same value drives the panel's corner animation below. The
        // corners are squared again once the player settles (see the completion
        // block) so it covers the whole screen with no edge gaps.
        let finalCornerRadius = toVC.roundCornersForPlayerTransition()

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

        let floating: UIImageView?
        if isVideoShown {
            floating = nil
        } else {
            let art = makeFloatingArtwork(
                image: toArtwork.image ?? miniArtwork.imageView?.image,
                frame: sourceArtFrame,
                cornerRadius: miniArtwork.layer.cornerRadius
            )
            container.addSubview(art)
            floating = art
        }

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
            panel.layer.cornerRadius = finalCornerRadius
            toView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating?.frame = destArtFrame
            floating?.layer.cornerRadius = toArtwork.layer.cornerRadius
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
            // Settled full-screen: square the corners so the player fills the
            // screen and the device display mask renders the curvature exactly.
            toVC.resetCornersAfterPlayerTransition()
            panel.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            floating?.removeFromSuperview()
            self.miniSnapshotController = nil
            // Restore the artwork only for audio — `update()` on the player
            // controller already left video artwork effectively hidden.
            if !self.isVideoShown {
                toArtwork.alpha = 1
            }
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Dismiss

    private func animateDismiss(context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        let fromVC = fullPlayer
        let miniVC = miniPlayer
        fromVC.loadViewIfNeeded()
        fromVC.nowPlayingItem.loadViewIfNeeded()
        miniVC.loadViewIfNeeded()

        guard
            let fromView = fromVC.viewIfLoaded,
            let mini = miniVC.viewIfLoaded,
            let miniArtwork = miniVC.podcastArtwork,
            let fromArtwork = fromVC.nowPlayingItem.artworkImageView
        else {
            // This should never happen — fall back to a basic fade-out.
            guard let fromView = fromVC.viewIfLoaded else {
                context.completeTransition(true)
                return
            }
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
                fromView.alpha = 0
            } completion: { _ in
                let wasCancelled = context.transitionWasCancelled
                if wasCancelled {
                    fromView.alpha = 1
                } else {
                    fromView.removeFromSuperview()
                }
                context.completeTransition(!wasCancelled)
            }
            return
        }

        let finalFrame = fromView.frame
        // If the user dragged the player down before releasing, fromView's
        // origin.y holds that offset. Start the panel at that offset so the
        // dismiss animation picks up where the gesture left off instead of
        // snapping back to y=0.
        let dragOffset = max(0, fromView.frame.origin.y)
        let miniFrame = mini.convert(mini.bounds, to: container)
        let miniCornerRadius = miniPillCornerRadius(for: miniFrame)
        let destArtFrame = miniArtwork.convert(miniArtwork.bounds, to: container)
        // The full-player artwork only lives on the Now Playing tab — on the
        // other tabs `nowPlayingItem` is scrolled horizontally off-screen
        // inside `mainScrollView`, so morphing an artwork view back to the
        // mini player would slide it across the screen from nowhere visible.
        // Skip the morph entirely in that case and let the mini snapshot's
        // own artwork appear in place instead. Video podcasts also skip the
        // morph because `episodeImage` is hidden behind the floating video.
        let shouldMorphArtwork = fromVC.tabsView.currentTab == 0 && !isVideoShown
        let sourceArtFrame = container.convert(fromArtwork.convert(fromArtwork.bounds, to: fromView), from: fromView)
        let sourceArtCornerRadius = fromArtwork.layer.cornerRadius
        let isMiniInline = mini.traitCollection.tabAccessoryEnvironment == .inline

        if shouldMorphArtwork {
            miniArtwork.alpha = 0
            fromArtwork.alpha = 0
        }

        // Round the player's corners (if a drag didn't already) and resolve the
        // display radius so the panel can morph its corners to match, then drop
        // fromView's own clipping — the panel handles the single outer clip
        // during the descent.
        let finalCornerRadius = fromVC.roundCornersForPlayerTransition()
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
            isInline: isMiniInline,
            artworkImage: shouldMorphArtwork ? nil : miniArtwork.imageView?.image
        )
        miniSnapshot.alpha = 0
        container.addSubview(miniSnapshot)
        miniSnapshotController?.synchronizeScrollingTitleAnimation(with: miniVC)

        let floating: UIImageView?
        if shouldMorphArtwork {
            let art = makeFloatingArtwork(
                image: fromArtwork.image ?? miniArtwork.imageView?.image,
                frame: sourceArtFrame,
                cornerRadius: sourceArtCornerRadius
            )
            container.addSubview(art)
            floating = art
        } else {
            floating = nil
        }

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
            if let floating {
                floating.frame = destArtFrame
                floating.layer.cornerRadius = miniArtwork.layer.cornerRadius
            }
            // Mini chrome rides down from the top, pinned to the panel's top
            // edge, fading in over the full duration so it materializes during
            // the descent instead of popping in at the end.
            miniSnapshot.frame.origin.y = miniFrame.minY
        } completion: { _ in
            panel.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            mini.subviews.forEach { $0.alpha = 1 }
            floating?.removeFromSuperview()
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
    ///
    /// When `artworkImage` is non-nil the clone displays it directly; otherwise
    /// the clone's artwork slot is hidden because a floating artwork view
    /// occupies that space during the morph.
    private func makeMiniSnapshot(frame: CGRect, cornerRadius: CGFloat, isInline: Bool, artworkImage: UIImage? = nil) -> UIView {
        let clone = MiniPlayerViewController()
        clone.loadViewIfNeeded()
        guard let cloneView = clone.viewIfLoaded else {
            // Pathological: view failed to load. Return an empty placeholder
            // so the caller can still animate; the snapshot just won't be
            // visible.
            return UIView(frame: frame)
        }
        // The clone isn't hosted in a `UITabAccessory`, so its
        // `tabAccessoryEnvironment` trait stays at the default — force the
        // layout flavor that matches the live mini player.
        clone.setForcedInlineLayout(isInline)
        if let artworkImage, let artworkImageView = clone.podcastArtwork?.imageView {
            artworkImageView.image = artworkImage
        } else {
            clone.podcastArtwork?.isHidden = true
        }
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
    private struct ScreenCornerRadiusCacheKey: Equatable {
        let bounds: CGRect
        let userInterfaceIdiom: UIUserInterfaceIdiom
        let horizontalSizeClass: UIUserInterfaceSizeClass
        let verticalSizeClass: UIUserInterfaceSizeClass
        let displayScale: CGFloat

        @MainActor
        init(window: UIWindow) {
            bounds = window.bounds
            userInterfaceIdiom = window.traitCollection.userInterfaceIdiom
            horizontalSizeClass = window.traitCollection.horizontalSizeClass
            verticalSizeClass = window.traitCollection.verticalSizeClass
            displayScale = window.traitCollection.displayScale
        }
    }

    private static var screenCornerRadiusCache: [ObjectIdentifier: (key: ScreenCornerRadiusCacheKey, radius: CGFloat)] = [:]

    /// Rounds the player's corners to the device's display radius for the zoom
    /// transition and the interactive drag-dismiss. Returns the radius so the
    /// transition's morph panel can animate to the same value.
    @discardableResult
    func roundCornersForPlayerTransition() -> CGFloat {
        let radius = Self.screenCornerRadius(for: view)
        view.layer.cornerRadius = radius
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return radius
    }

    /// Squares the player's corners once it's settled full-screen so it covers
    /// the whole screen. The device's display mask then renders the screen
    /// curvature exactly — keeping a rounded corner on the view itself leaves
    /// thin gaps at the edges because a layer corner can't match the hardware
    /// mask precisely.
    func resetCornersAfterPlayerTransition() {
        view.layer.cornerRadius = 0
    }

    /// The device's display corner radius (≈55 on modern iPhones, 30 on iPad,
    /// 0 on square-cornered devices), or the window's own radius when the app is
    /// resized on iPad. No public API exposes it directly, so measure it with
    /// the iOS 26 container-concentric API on a throwaway full-window probe: a
    /// window-filling view reports its concentric corner radius as the display
    /// radius. Falls back to an iPhone-scale value if there's no window yet.
    static func screenCornerRadius(for view: UIView) -> CGFloat {
        guard let host = view.window else { return 55 }
        let cacheKey = ScreenCornerRadiusCacheKey(window: host)
        let cacheIdentifier = ObjectIdentifier(host)
        if let cached = screenCornerRadiusCache[cacheIdentifier], cached.key == cacheKey {
            return cached.radius
        }
        let probe = UIView(frame: host.bounds)
        probe.cornerConfiguration = .corners(radius: .containerConcentric())
        host.addSubview(probe)
        probe.isUserInteractionEnabled = false
        probe.isAccessibilityElement = false
        probe.accessibilityElementsHidden = true
        probe.layoutIfNeeded()
        let radius = probe.effectiveRadius(corner: .allCorners)
        probe.removeFromSuperview()
        screenCornerRadiusCache[cacheIdentifier] = (key: cacheKey, radius: radius)
        return radius
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
