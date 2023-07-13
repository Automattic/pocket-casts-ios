import Combine
import PocketCastsDataModel

// MARK: - BookmarkListRouter
protocol BookmarkListRouter {
    func bookmarkPlay(_ bookmark: Bookmark)
}

class BookmarkListViewModel: MultiSelectListViewModel<Bookmark> {
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

    func reload() {
        items = episode.map { bookmarkManager.bookmarks(for: $0) } ?? []
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

    // MARK: - View Methods

    func bookmarkTapped(_ bookmark: Bookmark) {
        guard isMultiSelecting else {
            return
        }

        toggleSelected(bookmark)
    }

    func bookmarkPlayTapped(_ bookmark: Bookmark) {
        router?.bookmarkPlay(bookmark)
    }

    func editSelectedBookmarks() {
        guard let bookmark = selectedItems.first else { return }

        print("TODO \(bookmark)")
    }

    func deleteSelectedBookmarks() {
        guard numberOfSelectedItems > 0 else { return }

        let items = Array(selectedItems)

        confirmDeletion { [weak self] in
            self?.actuallyDelete(items)
        }
    }
}

private extension BookmarkListViewModel {
    func confirmDeletion(_ delete: @escaping () -> Void) {
        guard let controller = SceneHelper.rootViewController() else { return }

        let alert = UIAlertController(title: L10n.bookmarkDeleteWarningTitle,
                                      message: L10n.bookmarkDeleteWarningBody,
                                      preferredStyle: .alert)

        alert.addAction(.init(title: L10n.cancel, style: .cancel))
        alert.addAction(.init(title: L10n.delete, style: .destructive, handler: { _ in
            delete()
        }))

        controller.present(alert, animated: true, completion: nil)
    }

    func actuallyDelete(_ items: [Bookmark]) {
    }
}
