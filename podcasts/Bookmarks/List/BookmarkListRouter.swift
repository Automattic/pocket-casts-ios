import PocketCastsDataModel
import UIKit

@MainActor
protocol BookmarkListRouter: AnyObject {
    func bookmarkPlay(_ bookmark: Bookmark) async throws
    func bookmarkEdit(_ bookmark: Bookmark)
    func bookmarkShare(_ bookmark: Bookmark)

    /// Opens the bookmark in full, with the transcript passage it captured
    func bookmarkDetails(_ bookmark: Bookmark, source: BookmarkAnalyticsSource)

    /// Optional: Dismisses the presented bookmark list, if applicable.
    func dismissBookmarksList()

    /// Called when a view model needs to present a view controller, such as an alert.
    func presentBookmarkController(_ controller: UIViewController)
}

extension BookmarkListRouter {
    func dismissBookmarksList() { /* NOOP */ }
}

// MARK: - UIViewController subclass default implementation

extension BookmarkListRouter where Self: UIViewController {
    func presentBookmarkController(_ controller: UIViewController) {
        present(controller, animated: true)
    }

    /// Pushed where the list already sits in a navigation stack, presented where it doesn't,
    /// such as the player's bookmarks tab
    func bookmarkDetails(_ bookmark: Bookmark, source: BookmarkAnalyticsSource) {
        let controller = BookmarkDetailsViewController(bookmark: bookmark, source: source)

        if let navigationController {
            navigationController.pushViewController(controller, animated: true)
        } else {
            present(SJUIUtils.navController(for: controller), animated: true)
        }
    }
}
