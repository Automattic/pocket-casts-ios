import Foundation
import PocketCastsUtils

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = dismissed as? PlayerContainerViewController else {
            return nil
        }

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            return PlayerZoomAnimator(isPresenting: false, fullPlayer: fullPlayer) { [weak self] in self }
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, dismissVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = presented as? PlayerContainerViewController else {
            return nil
        }

        // Reset the unused gesture velocity for parity with the legacy
        // animator — Liquid Glass's zoom transition doesn't carry it through.
        pendingPresentVelocity = 0

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            // Blank the player view before UIKit can position and render it
            // at its final frame — otherwise the first render shows the
            // fully-opaque player flashing in behind the panel.
            fullPlayer.loadViewIfNeeded()
            fullPlayer.view.alpha = 0
            return PlayerZoomAnimator(isPresenting: true, fullPlayer: fullPlayer) { [weak self] in self }
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage)
    }
}
