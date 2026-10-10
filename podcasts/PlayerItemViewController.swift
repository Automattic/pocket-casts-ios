import UIKit

@MainActor
protocol PlayerItemContainerDelegate: AnyObject {
    func scrollToCurrentChapter()
    func scrollToNowPlaying()
    func scrollToBookmarks()
    func navigateToPodcast()
    func dismissTranscript()
}

@MainActor
class PlayerItemViewController: SimpleNotificationsViewController {
    func willBeAddedToPlayer() {}
    func willBeRemovedFromPlayer() {}

    func themeDidChange() {}

    weak var scrollViewHandler: UIScrollViewDelegate?
    weak var containerDelegate: PlayerItemContainerDelegate?

    /// Set by the container when it paints the player background itself
    /// (`FeatureFlag.largeScreenNowPlaying`), so the item keeps a transparent background.
    var usesLargeScreenStyle = false

    // MARK: - Present

    /// Always present from the parent VC
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        parent?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
