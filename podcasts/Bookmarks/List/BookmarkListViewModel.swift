import Combine
import PocketCastsDataModel

class BookmarkListViewModel: ObservableObject {
    @Published var bookmarkCount: Int = 0
    @Published var bookmarks: [Bookmark] = []

    private let bookmarkManager: BookmarkManager
    private var cancellables = Set<AnyCancellable>()

    weak var episode: BaseEpisode? = nil {
        didSet {
            reload()
        }
    }

    init(bookmarkManager: BookmarkManager) {
        self.bookmarkManager = bookmarkManager

        listenForAddedBookmarks()
    }

    func reload() {
        let bookmarks = episode.map { bookmarkManager.bookmarks(for: $0) } ?? []

        bookmarkCount = bookmarks.count
        self.bookmarks = bookmarks
    }

    private func listenForAddedBookmarks() {
        bookmarkManager.onBookmarkCreated
            .filter { [weak self] episode, _ in
                self?.episode?.uuid == episode.uuid
            }
            .sink { [weak self] _, _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    func bookmarkTapped(_ bookmark: Bookmark) {
        print("Tapped")
    }

    func bookmarkPlayTapped(_ bookmark: Bookmark) {
        PlaybackManager.shared.seekTo(time: bookmark.time, startPlaybackAfterSeek: true)
    }
}
