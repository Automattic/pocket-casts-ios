import Combine
import PocketCastsDataModel
import SwiftUI

class BookmarkEpisodeListController: ThemedHostingController<BookmarkEpisodeListView> {
    private let playbackManager: PlaybackManager
    private let bookmarkManager: BookmarkManager
    let viewModel: BookmarkEpisodeListViewModel

    private var cancellables = Set<AnyCancellable>()

    init(episode: BaseEpisode, displayMode: BookmarkEpisodeListView.DisplayMode = .list,
         bookmarkManager: BookmarkManager = PlaybackManager.shared.bookmarkManager,
         playbackManager: PlaybackManager = .shared, themeOverride: Theme.ThemeType? = nil) {

        self.bookmarkManager = bookmarkManager
        self.playbackManager = playbackManager

        let viewModel = BookmarkEpisodeListViewModel(episode: episode,
                                                      bookmarkManager: bookmarkManager,
                                                      sortOption: Settings.episodeBookmarksSort)
        viewModel.analyticsSource = (episode is Episode) ? .episodes : .files

        self.viewModel = viewModel

        if let themeOverride {
            super.init(rootView: BookmarkEpisodeListView(viewModel: viewModel, style: OverrideThemedBookmarksStyle(overrideTheme: themeOverride), displayMode: displayMode))
        } else {
            super.init(rootView: BookmarkEpisodeListView(viewModel: viewModel, displayMode: displayMode))
        }

        viewModel.router = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - BookmarkListRouter

extension BookmarkEpisodeListController: BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark) {
        playbackManager.playBookmark(bookmark, source: viewModel.analyticsSource)
    }

    func bookmarkEdit(_ bookmark: Bookmark) {
        let controller = BookmarkEditTitleViewController(manager: bookmarkManager,
                                                         bookmark: bookmark,
                                                         state: .updating)

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
