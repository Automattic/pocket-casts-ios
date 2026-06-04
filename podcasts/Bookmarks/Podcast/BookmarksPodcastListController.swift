import Combine
import PocketCastsDataModel
import SwiftUI

class BookmarksPodcastListController: ThemedHostingController<BookmarksPodcastListView> {
    private let playbackManager: PlaybackManager
    private let bookmarkManager: BookmarkManager
    private let viewModel: BookmarkPodcastListViewModel

    init(podcast: Podcast,
         bookmarkManager: BookmarkManager = PlaybackManager.shared.bookmarkManager,
         playbackManager: PlaybackManager = .shared) {

        self.bookmarkManager = bookmarkManager
        self.playbackManager = playbackManager

        let sortOption = Settings.podcastBookmarksSort
        let viewModel = BookmarkPodcastListViewModel(podcast: podcast,
                                                      bookmarkManager: bookmarkManager,
                                                      sortOption: sortOption)
        viewModel.analyticsSource = .podcasts

        self.viewModel = viewModel
        super.init(rootView: .init(viewModel: viewModel))

        viewModel.router = self
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - BookmarkListRouter

extension BookmarksPodcastListController: BookmarkListRouter {
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
        Analytics.track(.bookmarkShareTapped, source: viewModel.analyticsSource, properties: ["podcast_uuid": episode.podcastUuid, "episode_uuid": bookmark.episodeUuid])
        SharingModal.show(option: .bookmark(episode, bookmark.time), from: .podcastScreen, in: self)
    }

    func bookmarkDetail(_ bookmark: Bookmark) {
        let detailView = BookmarkDetailView(
            bookmark: bookmark,
            episode: bookmark.episode,
            onPlay: { [weak self] in
                self?.playbackManager.playBookmark(bookmark, source: self?.viewModel.analyticsSource ?? .podcasts)
            },
            onEdit: { [weak self] done in
                guard let self else { return }
                presentBookmarkEditor(bookmark: bookmark, bookmarkManager: bookmarkManager, analyticsSource: viewModel.analyticsSource) { [weak self] in
                    self?.viewModel.reload()
                    done()
                }
            },
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
