import Combine
import PocketCastsDataModel
import PocketCastsServer
import SwiftUI

class BookmarkListViewModel: SearchableListViewModel<Bookmark> {
    typealias SortSetting = Binding<BookmarkSortOption>

    weak var router: BookmarkListRouter?

    let bookmarkManager: BookmarkManager

    var sortOption: BookmarkSortOption {
        didSet {
            Analytics.track(.bookmarksSortByChanged, source: analyticsSource, properties: [
                "sort_order": sortOption
            ])
            sortSettingValue = sortOption
        }
    }

    var availableSortOptions: [BookmarkSortOption] {
        [.newestToOldest, .oldestToNewest, .timestamp]
    }

    var bookmarks: [Bookmark] {
        isSearching ? filteredItems : items
    }

    var bookmarkCount: Int {
        isSearching ? numberOfFilteredItems : numberOfItems
    }

    var cancellables = Set<AnyCancellable>()
    @Binding private var sortSettingValue: BookmarkSortOption

    let feature: PaidFeature = .bookmarks
    var analyticsSource: BookmarkAnalyticsSource = .unknown

    init(bookmarkManager: BookmarkManager, sortOption: SortSetting) {
        self.bookmarkManager = bookmarkManager
        self._sortSettingValue = sortOption
        self.sortOption = sortOption.wrappedValue

        super.init()

        addListeners()
    }

    func reload() { }

    func dismiss() {
        router?.dismissBookmarksList()
    }

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

        ServerNotifications.syncCompleted.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookmark in
                self?.reload()
            }
            .store(in: &cancellables)

        feature.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookmark in
                self?.reload()
                self?.objectWillChange.send()
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
        Analytics.track(.bookmarksEmptyGoToHeadphoneSettings, source: analyticsSource)

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
        let currentSort = sortOption

        optionPicker.addActions(availableSortOptions.map({ option in
                .init(label: option.label, selected: option == currentSort) { [weak self] in
                self?.sorted(by: option)
            }
        }))

        optionPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
}

private extension BookmarkListViewModel {
    func confirmDeletion(_ delete: @escaping () -> Void) {
        guard let router else { return }

        let alert = UIAlertController(title: L10n.bookmarkDeleteWarningTitle,
                                      message: L10n.bookmarkDeleteWarningBody,
                                      preferredStyle: .alert)

        alert.addAction(.init(title: L10n.cancel, style: .cancel))
        alert.addAction(.init(title: L10n.delete, style: .destructive, handler: { _ in
            delete()
        }))

        router.presentBookmarkController(alert)
    }

    func actuallyDelete(_ items: [Bookmark]) {
        Task {
            guard await bookmarkManager.remove(items) else {
                return
            }

            Analytics.track(.bookmarkDeleted, source: analyticsSource)
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
        case .episode:
            return L10n.episode
        case .podcastAndEpisode:
            return L10n.podcastAndEpisode
        }
    }
}

extension Bookmark: SearchableDataModel {
    /// Allows bookmarks to be searched by their title or the episode title
    var searchableContent: String {
        [title, episode?.title].compactMap { $0 }.joined(separator: " ")
    }
}
