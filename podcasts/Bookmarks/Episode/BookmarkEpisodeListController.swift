import Combine
import PocketCastsDataModel
import SwiftUI

@MainActor
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

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - BookmarkListRouter

extension BookmarkEpisodeListController: BookmarkListRouter {
    /// The list is shown within the episode's own details, so its artwork doesn't open them again
    var opensBookmarkEpisode: Bool { false }

    func bookmarkPlay(_ bookmark: Bookmark) async throws {
        try await playbackManager.playBookmark(bookmark, source: viewModel.analyticsSource)
    }

    func bookmarkEdit(_ bookmark: Bookmark) {
        let controller = BookmarkEditTitleViewController(manager: bookmarkManager,
                                                         bookmark: bookmark,
                                                         state: .updating,
                                                         style: .themed,
                                                         source: viewModel.analyticsSource)

        present(controller, animated: true)
    }

    func bookmarkShare(_ bookmark: Bookmark) {
        guard let episode = viewModel.episode as? Episode else {
            return
        }
        Analytics.track(.bookmarkShareTapped, source: viewModel.analyticsSource, properties: ["podcast_uuid": episode.podcastUuid, "episode_uuid": bookmark.episodeUuid])

        SharingModal.show(option: .bookmark(episode, bookmark.time), from: .episodeDetail, in: self)
    }

    func dismissBookmarksList() {
        dismiss(animated: true)
    }
}
