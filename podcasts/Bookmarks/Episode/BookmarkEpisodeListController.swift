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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func themeDidChange() {
        super.themeDidChange()
        view.backgroundColor = .clear
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
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
        guard let episode = viewModel.episode as? Episode else {
            return
        }
        Analytics.track(.bookmarkShareTapped, source: viewModel.analyticsSource, properties: ["podcast_uuid": episode.podcastUuid, "episode_uuid": bookmark.episodeUuid])

        SharingModal.show(option: .bookmark(episode, bookmark.time), from: .episodeDetail, in: self)
    }

    func bookmarkDetail(_ bookmark: Bookmark) {
        let detailView = BookmarkDetailView(
            bookmark: bookmark,
            episode: bookmark.episode,
            onPlay: { [weak self] in
                self?.playbackManager.playBookmark(bookmark, source: self?.viewModel.analyticsSource ?? .episodes)
            },
            onEdit: { [weak self] done in
                guard let self else { return }
                presentBookmarkEditor(bookmark: bookmark, bookmarkManager: bookmarkManager, analyticsSource: viewModel.analyticsSource) { [weak self] in
                    self?.viewModel.reload()
                    done()
                }
            },
            onShare: bookmark.episode is Episode ? { [weak self] in
                self?.bookmarkShare(bookmark)
            } : nil,
            bookmarkLookup: { [weak self] uuid in
                self?.bookmarkManager.bookmark(for: uuid)
            }
        )
        let controller = ThemedHostingController(rootView: detailView)
        navigationController?.pushViewController(controller, animated: true)
    }

    func dismissBookmarksList() {
        dismiss(animated: true)
    }
}
