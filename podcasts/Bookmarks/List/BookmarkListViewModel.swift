import Combine
import PocketCastsDataModel

// MARK: - BookmarkListRouter
protocol BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark)
}

class BookmarkListViewModel: MutliSelectListViewModel<Bookmark> {
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
        super.init()

        listenForAddedBookmarks()
    }

    override func reload() {
        items = episode.map { bookmarkManager.bookmarks(for: $0) } ?? []

        super.reload()
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
