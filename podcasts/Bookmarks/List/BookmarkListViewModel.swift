import Combine
import PocketCastsDataModel

protocol BookmarkListRouter: AnyObject {
    func bookmarkPlay(_ bookmark: Bookmark)
    func bookmarkEdit(_ bookmark: Bookmark)
}

class BookmarkListViewModel: MultiSelectListViewModel<Bookmark> {
    typealias BookmarkSettings = Constants.UserDefaults.bookmarks

    weak var router: BookmarkListRouter?

    private let bookmarkManager: BookmarkManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var sortOption: BookmarkSortOption {
        didSet {
            BookmarkSettings.playerSort.save(sortOption)
        }
    }

    weak var episode: BaseEpisode? = nil {
        didSet {
            reload()
        }
    }

    init(bookmarkManager: BookmarkManager) {
        self.bookmarkManager = bookmarkManager
        self.sortOption = BookmarkSettings.playerSort.value

        super.init()

        addListeners()
    }

    func reload() {
        items = episode.map { bookmarkManager.bookmarks(for: $0) } ?? []
    }

    /// Reload a single item from the list
    func refresh(bookmark: Bookmark) {
        guard let index = items.firstIndex(of: bookmark) else { return }

        items.replaceSubrange(index...index, with: [bookmark])
    }

    private func addListeners() {
        bookmarkManager.onBookmarkCreated
            .filter { [weak self] event in
                self?.episode?.uuid == event.episode
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)

        bookmarkManager.onBookmarkChanged
            .filter { [weak self] event in
                self?.items.contains(where: { $0.uuid == event.uuid }) ?? false
            }
            .compactMap { [weak self] event in
                self?.bookmarkManager.bookmark(for: event.uuid)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookmark in
                self?.refresh(bookmark: bookmark)
            }
            .store(in: &cancellables)
    }

    // MARK: - View Methods

    func bookmarkPlayTapped(_ bookmark: Bookmark) {
        router?.bookmarkPlay(bookmark)
    }

    func editSelectedBookmarks() {
        guard let bookmark = selectedItems.first else { return }

        router?.bookmarkEdit(bookmark)
        toggleMultiSelection()
    }

    func deleteSelectedBookmarks() {
        guard numberOfSelectedItems > 0 else { return }

        let items = Array(selectedItems)

        confirmDeletion { [weak self] in
            self?.actuallyDelete(items)
            self?.toggleMultiSelection()
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
        Task {
            guard await bookmarkManager.remove(items) else {
                return
            }

            reload()
        }
    }
}
