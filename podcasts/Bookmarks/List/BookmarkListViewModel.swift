import Combine
import PocketCastsDataModel

// MARK: - BookmarkListRouter
protocol BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark)
}

    var router: BookmarkListRouter?

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
        router?.bookmarkPlay(bookmark)
    }
}
