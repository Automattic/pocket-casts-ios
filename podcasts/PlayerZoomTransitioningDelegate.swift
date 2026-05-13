import UIKit

@available(iOS 26, *)
final class PlayerZoomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    let miniPlayerProvider: () -> MiniPlayerView?

    init(miniPlayerProvider: @escaping () -> MiniPlayerView?) {
        self.miniPlayerProvider = miniPlayerProvider
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        PlayerZoomAnimator(isPresenting: true, miniPlayerProvider: miniPlayerProvider)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        PlayerZoomAnimator(isPresenting: false, miniPlayerProvider: miniPlayerProvider)
    }
}

@available(iOS 26, *)
final class PlayerZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    let miniPlayerProvider: () -> MiniPlayerView?

    private let presentDuration: TimeInterval = 0.5
    private let dismissDuration: TimeInterval = 0.45
    /// iOS 26 modal-sheet large corner radius. Matches the device display radius
    /// closely enough on modern iPhones that the full player corners read as
    /// continuous with the screen edges.
    private let finalCornerRadius: CGFloat = 55

    init(isPresenting: Bool, miniPlayerProvider: @escaping () -> MiniPlayerView?) {
        self.isPresenting = isPresenting
        self.miniPlayerProvider = miniPlayerProvider
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? presentDuration : dismissDuration
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
        guard
            let toVC = context.viewController(forKey: .to) as? FullPlayerViewController,
            let mini = miniPlayerProvider()
        else {
            context.completeTransition(false)
            return
        }

        let finalFrame = context.finalFrame(for: toVC)
        let toView = toVC.view!
        let miniFrame = mini.convert(mini.bounds, to: container)
        let miniCornerRadius = miniPillCornerRadius(for: miniFrame)
        let sourceArtFrame = mini.artworkView.convert(mini.artworkView.bounds, to: container)

        mini.artworkView.isHidden = true
        toVC.artworkView.isHidden = true
        mini.isHidden = true

        // Header sits at the top of toView, which is the area visible through
        // the small panel at the start of the transition. Hide it now and fade
        // it back in partway through, once the panel has grown enough that the
        // header doesn't pop in awkwardly.
        toVC.setHeaderHidden(true, animated: false)
        toVC.setHeaderHidden(false, animated: true, delay: presentDuration * 0.4)

        // Lay out toView at its final frame so we can read the destination
        // artwork frame from its final layout, then re-parent it into the panel.
        toView.frame = finalFrame
        container.addSubview(toView)
        toView.layoutIfNeeded()
        let destArtFrame = container.convert(toVC.computedArtworkFrame(), from: toView)
        toView.removeFromSuperview()

        // Give toView the final corner radius now so the rounded corners persist
        // after the panel is removed at the end of the transition.
        let originalBackground = toView.backgroundColor
        toView.backgroundColor = .clear
        toView.layer.cornerRadius = finalCornerRadius
        toView.layer.cornerCurve = .continuous
        toView.clipsToBounds = true

        let panel = makePanel(
            frame: miniFrame,
            cornerRadius: miniCornerRadius,
            color: originalBackground ?? .black,
            colorAlpha: 0
        )
        container.addSubview(panel.view)

        toView.frame = CGRect(x: -miniFrame.minX, y: 0, width: finalFrame.width, height: finalFrame.height)
        panel.view.addSubview(toView)

        let miniSnapshot = makeMiniSnapshot(frame: miniFrame, cornerRadius: miniCornerRadius)
        container.addSubview(miniSnapshot)

        let floating = makeFloatingArtwork(
            frame: sourceArtFrame,
            cornerRadius: mini.artworkView.layer.cornerRadius
        )
        container.addSubview(floating)

        UIView.animate(
            withDuration: presentDuration,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut]
        ) {
            panel.view.frame = container.bounds
            panel.view.layer.cornerRadius = self.finalCornerRadius
            toView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating.frame = destArtFrame
            floating.layer.cornerRadius = toVC.artworkView.layer.cornerRadius
            panel.colorOverlay.alpha = 1
            // Mini chrome rides up pinned to the panel's top edge and fades out
            // over the full duration, so it animates the whole way rather than
            // vanishing in the first frames.
            miniSnapshot.frame.origin.y = 0
            miniSnapshot.alpha = 0
        } completion: { _ in
            container.addSubview(toView)
            toView.frame = finalFrame
            toView.backgroundColor = originalBackground
            panel.view.removeFromSuperview()
            miniSnapshot.removeFromSuperview()
            floating.removeFromSuperview()
            mini.isHidden = false
            mini.artworkView.isHidden = false
            toVC.artworkView.isHidden = false
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Dismiss

    private func animateDismiss(context: UIViewControllerContextTransitioning) {
        let container = context.containerView
        guard
            let fromVC = context.viewController(forKey: .from) as? FullPlayerViewController,
            let mini = miniPlayerProvider()
        else {
            context.completeTransition(false)
            return
        }

        let fromView = fromVC.view!
        let finalFrame = fromView.frame
        let miniFrame = mini.convert(mini.bounds, to: container)
        let miniCornerRadius = miniPillCornerRadius(for: miniFrame)
        let sourceArtFrame = container.convert(fromVC.computedArtworkFrame(), from: fromView)
        let destArtFrame = mini.artworkView.convert(mini.artworkView.bounds, to: container)

        mini.artworkView.isHidden = true
        fromVC.artworkView.isHidden = true
        mini.isHidden = true

        // The panel handles outer clipping with the iOS 26 corner radius, so
        // remove the corner radius from fromView to avoid double-clipping.
        let originalBackground = fromView.backgroundColor
        fromView.backgroundColor = .clear
        fromView.layer.cornerRadius = 0
        fromView.clipsToBounds = false

        let panel = makePanel(
            frame: container.bounds,
            cornerRadius: finalCornerRadius,
            color: originalBackground ?? .black,
            colorAlpha: 1
        )
        container.insertSubview(panel.view, belowSubview: fromView)

        fromView.removeFromSuperview()
        fromView.frame = CGRect(x: 0, y: 0, width: finalFrame.width, height: finalFrame.height)
        panel.view.addSubview(fromView)

        let miniSnapshot = makeMiniSnapshot(
            frame: CGRect(x: miniFrame.minX, y: 0, width: miniFrame.width, height: miniFrame.height),
            cornerRadius: miniCornerRadius
        )
        miniSnapshot.alpha = 0
        container.addSubview(miniSnapshot)

        let floating = makeFloatingArtwork(
            frame: sourceArtFrame,
            cornerRadius: fromVC.artworkView.layer.cornerRadius
        )
        container.addSubview(floating)

        // Fade the full-player contents out faster than the panel shrinks, so
        // the title / controls don't visibly squish during the descent. The
        // floating artwork keeps morphing in its own animation.
        UIView.animate(withDuration: dismissDuration * 0.45, delay: 0, options: [.curveEaseOut]) {
            fromView.alpha = 0
        }

        UIView.animate(
            withDuration: dismissDuration,
            delay: 0,
            usingSpringWithDamping: 0.95,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut]
        ) {
            panel.view.frame = miniFrame
            panel.view.layer.cornerRadius = miniCornerRadius
            fromView.frame = CGRect(x: -miniFrame.minX, y: 0, width: finalFrame.width, height: finalFrame.height)
            floating.frame = destArtFrame
            floating.layer.cornerRadius = mini.artworkView.layer.cornerRadius
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
            fromVC.artworkView.isHidden = false
            mini.isHidden = false
            mini.artworkView.isHidden = false
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

    /// Builds a live `MiniPlayerView` clone instead of a bitmap snapshot.
    /// Snapshot APIs (`snapshotView`, `drawHierarchy`, `layer.render`) all
    /// produced partial renders for `MiniPlayerView` inside `UITabAccessory` —
    /// labels and stack-view buttons dropped out. A real view hierarchy
    /// renders reliably and animates the same way.
    private func makeMiniSnapshot(frame: CGRect, cornerRadius: CGFloat) -> MiniPlayerView {
        let clone = MiniPlayerView()
        clone.artworkView.isHidden = true
        clone.isUserInteractionEnabled = false
        clone.frame = frame
        clone.layer.cornerRadius = cornerRadius
        clone.layer.cornerCurve = .continuous
        clone.clipsToBounds = true
        clone.layoutIfNeeded()
        return clone
    }

    private func makeFloatingArtwork(frame: CGRect, cornerRadius: CGFloat) -> UIImageView {
        let v = UIImageView(image: PlayerArtwork.waveformImage)
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
