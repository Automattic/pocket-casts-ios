import Combine
import PocketCastsDataModel

protocol BookmarkListRouter: AnyObject {
    func bookmarkPlay(_ bookmark: Bookmark)
    func bookmarkEdit(_ bookmark: Bookmark)
    func dismissBookmarksList()

    var alertController: UIViewController? { get }
}

extension BookmarkListRouter {
    func dismissBookmarksList() { }

    var alertController: UIViewController? { SceneHelper.rootViewController() }
}

class BookmarkListViewModel: SearchableListViewModel<Bookmark> {
    typealias SortSetting = Constants.SettingValue<BookmarkSortOption>

    weak var router: BookmarkListRouter?

    let bookmarkManager: BookmarkManager

    var sortOption: BookmarkSortOption {
        didSet {
            sortSettingValue.save(sortOption)
        }
    }

    var bookmarks: [Bookmark] {
        isSearching ? filteredItems : items
    }

    var bookmarkCount: Int {
        isSearching ? numberOfFilteredItems : numberOfItems
    }

    var cancellables = Set<AnyCancellable>()
    private let sortSettingValue: SortSetting

    init(bookmarkManager: BookmarkManager, sortOption: SortSetting) {
        self.bookmarkManager = bookmarkManager
        self.sortSettingValue = sortOption
        self.sortOption = sortOption.value

        super.init()

        addListeners()
    }

    func reload() { }

    /// Reload a single item from the list
    func refresh(bookmark: Bookmark) {
        guard let index = items.firstIndex(of: bookmark) else { return }

        items.replaceSubrange(index...index, with: [bookmark])
    }

    func addListeners() {
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
}

// MARK: - View Methods

extension BookmarkListViewModel {
    func bookmarkPlayTapped(_ bookmark: Bookmark) {
        router?.bookmarkPlay(bookmark)
    }

    func editSelectedBookmarks() {
        guard let bookmark = selectedItems.first else { return }

        router?.bookmarkEdit(bookmark)
        toggleMultiSelection()
    }

    func sorted(by option: BookmarkSortOption) {
        sortOption = option
        reload()
    }

    func deleteSelectedBookmarks() {
        guard numberOfSelectedItems > 0 else { return }

        let items = Array(selectedItems)

        confirmDeletion { [weak self] in
            self?.actuallyDelete(items)
            self?.toggleMultiSelection()
        }
    }

    func openHeadphoneSettings() {
        router?.dismissBookmarksList()
        NavigationManager.sharedManager.navigateTo(NavigationManager.settingsHeadphoneKey)
    }
}

// MARK: - More Menu

extension BookmarkListViewModel {
    func showMoreOptions() {
        let optionPicker = OptionsPicker(title: nil)

        optionPicker.addActions([
            .init(label: L10n.selectBookmarks, icon: "option-multiselect") { [weak self] in
                self?.toggleMultiSelection()
            },
            .init(label: L10n.sortBy, secondaryLabel: sortOption.label, icon: "podcast-sort") { [weak self] in
                self?.showSortOptions()
            }
        ])

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    func showSortOptions() {
        let optionPicker = OptionsPicker(title: L10n.sortBy)

        let options: [BookmarkSortOption] = [.newestToOldest, .oldestToNewest, .timestamp]

        optionPicker.addActions(options.map({ option in
            .init(label: option.label) { [weak self] in
                self?.sorted(by: option)
            }
        }))

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
}

private extension BookmarkListViewModel {
    func confirmDeletion(_ delete: @escaping () -> Void) {
        guard let controller = router?.alertController else { return }

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

private extension BookmarkSortOption {
    var label: String {
        switch self {
        case .newestToOldest:
            return L10n.podcastsEpisodeSortNewestToOldest
        case .oldestToNewest:
            return L10n.podcastsEpisodeSortOldestToNewest
        case .timestamp:
            return L10n.sortOptionTimestamp
        }
    }
}

extension Bookmark: SearchableDataModel {
    var searchableContent: String {
        [title, episode?.title].compactMap { $0 }.joined()
    }
}
