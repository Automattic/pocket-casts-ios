import Foundation

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard let fullPlayer = presented as? PlayerContainerViewController else { return nil }

        let presentationController = FullPlayerPresentationController(presentedViewController: fullPlayer, presenting: presenting)
        presentationController.onNonAnimatedDismiss = { [weak self, weak fullPlayer] in
            guard let fullPlayer else { return }
            self?.fullScreenPlayerDidDismiss(fullPlayer)
        }
        return presentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = dismissed as? PlayerContainerViewController else {
            return nil
        }

        if #available(iOS 26.0, *) {
            return PlayerZoomAnimator(
                isPresenting: false,
                fullPlayer: fullPlayer,
                miniPlayer: self,
                interactiveVelocity: fullPlayer.dismissVelocity
            )
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.artworkImageView, dismissVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = presented as? PlayerContainerViewController else {
            return nil
        }

        let presentVelocity = pendingPresentVelocity
        pendingPresentVelocity = 0

        if #available(iOS 26.0, *) {
            // Blank the player view before UIKit can position and render it
            // at its final frame — otherwise the first render shows the
            // fully-opaque player flashing in behind the panel.
            fullPlayer.loadViewIfNeeded()
            fullPlayer.view.alpha = 0
            return PlayerZoomAnimator(
                isPresenting: true,
                fullPlayer: fullPlayer,
                miniPlayer: self,
                interactiveVelocity: presentVelocity
            )
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.artworkImageView)
    }
}

/// Behaves exactly like the default presentation controller UIKit creates for
/// `.custom` presentations, but reports dismissals that happened without a
/// transition animation. `dismiss(animated: false)` never consults the
/// transitioning delegate, so the animators' restore work is skipped — this is
/// the only UIKit hook that still fires in that case. Animated dismissals are
/// deliberately ignored: the animator's completion already handles them.
private final class FullPlayerPresentationController: UIPresentationController {
    var onNonAnimatedDismiss: (() -> Void)?

    private var isDismissalAnimated = false

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        isDismissalAnimated = presentedViewController.transitionCoordinator?.isAnimated ?? false
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        guard completed, !isDismissalAnimated else { return }

        onNonAnimatedDismiss?()
    }
}
