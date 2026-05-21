import Foundation
import PocketCastsUtils

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = dismissed as? PlayerContainerViewController else {
            return nil
        }

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            return PlayerZoomAnimator(
                isPresenting: false,
                fullPlayer: fullPlayer,
                miniPlayer: self,
                interactiveVelocity: fullPlayer.dismissVelocity
            )
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, dismissVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = presented as? PlayerContainerViewController else {
            return nil
        }

        let presentVelocity = pendingPresentVelocity
        pendingPresentVelocity = 0

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
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

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage)
    }
}
