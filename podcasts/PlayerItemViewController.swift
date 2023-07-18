import UIKit

protocol PlayerItemContainerDelegate: AnyObject {
    func scrollToCurrentChapter()
    func scrollToNowPlaying()
    func scrollToBookmarks()
}

class PlayerItemViewController: SimpleNotificationsViewController {
    func willBeAddedToPlayer() {}
    func willBeRemovedFromPlayer() {}

    func themeDidChange() {}

    weak var scrollViewHandler: UIScrollViewDelegate?
    weak var containerDelegate: PlayerItemContainerDelegate?
}
