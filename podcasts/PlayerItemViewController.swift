import UIKit

protocol PlayerItemContainerDelegate: AnyObject {
    func scrollToCurrentChapter()
    func scrollToNowPlaying()
    func scrollToBookmarks()
    func navigateToPodcast()
}

class PlayerItemViewController: SimpleNotificationsViewController {
    func willBeAddedToPlayer() {}
    func willBeRemovedFromPlayer() {}

    func themeDidChange() {}

    weak var scrollViewHandler: UIScrollViewDelegate?
    weak var containerDelegate: PlayerItemContainerDelegate?

    // MARK: - Present

    /// Always present from the parent VC
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        parent?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
