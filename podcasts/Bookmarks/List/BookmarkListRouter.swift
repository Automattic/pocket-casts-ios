import PocketCastsDataModel
import UIKit

@MainActor
protocol BookmarkListRouter: AnyObject {
    func bookmarkPlay(_ bookmark: Bookmark) async throws
    func bookmarkEdit(_ bookmark: Bookmark)
    func bookmarkShare(_ bookmark: Bookmark)

    /// Opens the bookmark in full, with the transcript passage it captured
    func bookmarkDetails(_ bookmark: Bookmark, source: BookmarkAnalyticsSource)

    /// Opens the episode the bookmark was made in
    func bookmarkEpisode(_ episode: Episode)

    /// Whether a tap on a bookmark's artwork opens the episode it was made in
    var opensBookmarkEpisode: Bool { get }

    /// Optional: Dismisses the presented bookmark list, if applicable.
    func dismissBookmarksList()

    /// Called when a view model needs to present a view controller, such as an alert.
    func presentBookmarkController(_ controller: UIViewController)
}

extension BookmarkListRouter {
    func dismissBookmarksList() { /* NOOP */ }

    var opensBookmarkEpisode: Bool { true }
}

// MARK: - UIViewController subclass default implementation

extension BookmarkListRouter where Self: UIViewController {
    func presentBookmarkController(_ controller: UIViewController) {
        present(controller, animated: true)
    }

    /// Pushed where the list already sits in a navigation stack, presented where it doesn't,
    /// such as the player's bookmarks tab
    func bookmarkDetails(_ bookmark: Bookmark, source: BookmarkAnalyticsSource) {
        let controller = BookmarkDetailsViewController(bookmark: bookmark, source: source, opensEpisode: opensBookmarkEpisode)

        if let navigationController {
            navigationController.pushViewController(controller, animated: true)
        } else {
            present(SJUIUtils.navController(for: controller), animated: true)
        }
    }

    func bookmarkEpisode(_ episode: Episode) {
        presentBookmarkEpisode(episode)
    }
}

extension UIViewController {
    /// Opens the episode a bookmark was made in, matching how Downloads, Starred and Up Next
    /// open episodes
    func presentBookmarkEpisode(_ episode: Episode) {
        guard let podcast = episode.parentPodcast() else { return }

        let controller = EpisodeDetailViewController(episode: episode, podcast: podcast, source: .bookmarks)
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true)
    }
}
