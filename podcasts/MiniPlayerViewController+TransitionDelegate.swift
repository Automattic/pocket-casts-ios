import Foundation
import PocketCastsUtils

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = dismissed as? PlayerContainerViewController else {
            return nil
        }

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            return LiquidGlassPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, gestureVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, dismissVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = presented as? PlayerContainerViewController else {
            return nil
        }

        // Consume the gesture velocity exactly once — taps and programmatic
        // opens reach this delegate with pendingPresentVelocity == 0.
        let presentVelocity = pendingPresentVelocity
        pendingPresentVelocity = 0

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            return LiquidGlassPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, gestureVelocity: presentVelocity)
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage)
    }
}
