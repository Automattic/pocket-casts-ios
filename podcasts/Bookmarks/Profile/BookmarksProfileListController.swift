import Combine
import PocketCastsDataModel
import SwiftUI

class BookmarksProfileListController: ThemedHostingController<BookmarksProfileListView> {
    private let playbackManager: PlaybackManager
    private let bookmarkManager: BookmarkManager
    private let viewModel: BookmarkPodcastListViewModel

    init(bookmarkManager: BookmarkManager = PlaybackManager.shared.bookmarkManager,
         playbackManager: PlaybackManager = .shared) {

        self.bookmarkManager = bookmarkManager
        self.playbackManager = playbackManager

        let sortOption = Settings.profileBookmarksSort
        let viewModel = BookmarkPodcastListViewModel(podcast: nil, bookmarkManager: bookmarkManager, sortOption: sortOption)

        viewModel.analyticsSource = .profile

        self.viewModel = viewModel
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.router = self
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        Analytics.track(.profileBookmarksShow)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - BookmarkListRouter

extension BookmarksProfileListController: BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark) {
        playbackManager.playBookmark(bookmark, source: viewModel.analyticsSource)
    }

    func bookmarkEdit(_ bookmark: Bookmark) {
        let controller = BookmarkEditTitleViewController(manager: bookmarkManager, bookmark: bookmark, state: .updating)
        controller.source = viewModel.analyticsSource

        present(controller, animated: true)
    }

    func bookmarkShare(_ bookmark: Bookmark) {
        guard let episode = bookmark.episode as? Episode else {
            return
        }
        let controller = SharingHelper.shared.createActivityController(episode: episode, shareTime: bookmark.time)

        present(controller, animated: true)
    }

    func dismissBookmarksList() {
        dismiss(animated: true)
    }
}
