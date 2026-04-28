import Foundation
import PocketCastsUtils

extension MiniPlayerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = dismissed as? PlayerContainerViewController else {
            return nil
        }

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            return LiquidGlassPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, dismissVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: dismissed, transition: .dismissing, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage, dismissVelocity: fullPlayer.dismissVelocity, fullPlayerYPosition: fullPlayer.finalYPositionWhenDismissing)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let fullPlayer = presented as? PlayerContainerViewController else {
            return nil
        }

        if FeatureFlag.liquidGlass.enabled, #available(iOS 26.0, *) {
            return LiquidGlassPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage)
        }

        return MiniPlayerToFullPlayerAnimator(fromViewController: self, toViewController: presented, transition: .presenting, miniPlayerArtwork: podcastArtwork, fullPlayerArtwork: fullPlayer.nowPlayingItem.episodeImage)
    }
}
