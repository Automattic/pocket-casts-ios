import Combine
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

@MainActor
class BookmarkListViewModel: SearchableListViewModel<Bookmark>, MultiSelectable {
    typealias SortSetting = Binding<BookmarkSortOption>

    weak var router: BookmarkListRouter?

    @Published var isMultiSelecting = false
    @Published var selectedIDs: Set<Bookmark.ID> = []

    var selectableItems: [Bookmark] { items }

    override var items: [Bookmark] {
        didSet {
            selectableItemsDidChange()
        }
    }

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

    @Published private(set) var loadingBookmarkUuid: String?

    init(bookmarkManager: BookmarkManager, sortOption: SortSetting) {
        self.bookmarkManager = bookmarkManager
        self._sortSettingValue = sortOption
        self.sortOption = sortOption.wrappedValue

        super.init()

        addListeners()
    }

    func reload() { }

    /// Outside of the multi selection, a tap opens the bookmark's details
    func tapped(item: Bookmark) {
        if isMultiSelecting {
            toggleSelected(item)
            return
        }

        guard FeatureFlag.smartBookmarks.enabled else { return }

        router?.bookmarkDetails(item, source: analyticsSource)
    }

    /// A tap on the artwork opens the episode the bookmark was made in, anything else,
    /// such as an uploaded file, falls back to the row's own tap behaviour
    func episodeTapped(_ episode: BaseEpisode, for bookmark: Bookmark) {
        guard !isMultiSelecting, router?.opensBookmarkEpisode == true,
              let episode = episode as? Episode else {
            tapped(item: bookmark)
            return
        }

        router?.bookmarkEpisode(episode)
    }

    func dismiss() {
        router?.dismissBookmarksList()
    }

    /// Reload a single item from the list
    func refresh(bookmark: Bookmark) {
        guard let index = items.firstIndex(where: { $0.id == bookmark.id }) else { return }

        items[index] = bookmark
    }

    func addListeners() {
        // Bookmarks can also be deleted from outside the list, such as from their details
        bookmarkManager.onBookmarksDeleted
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

        ServerNotifications.syncCompleted.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)

        feature.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - View Methods

extension BookmarkListViewModel {
    func bookmarkPlayTapped(_ bookmark: Bookmark) {
        Task { @MainActor [weak self] in
            let spinnerTask = Task { @MainActor in
                try await Task.sleep(for: .milliseconds(250))
                try Task.checkCancellation()
                self?.loadingBookmarkUuid = bookmark.uuid
            }

            do {
                try await self?.router?.bookmarkPlay(bookmark)
            } catch {
                HapticsHelper.triggerErrorHaptic()
                Toast.show(L10n.discoverEpisodeFailToLoad)
            }

            spinnerTask.cancel()
            self?.loadingBookmarkUuid = nil
        }
    }

    func editSelectedBookmarks() {
        guard let bookmark = selectedItems.first else { return }
        router?.bookmarkEdit(bookmark)
        toggleMultiSelection()
    }

    func shareSelectedBookmarks() {
        guard let bookmark = selectedItems.first else { return }

        router?.bookmarkShare(bookmark)
        toggleMultiSelection()
    }

    /// Whether the share swipe action should be shown for this bookmark
    func canShare(_ bookmark: Bookmark) -> Bool {
        bookmark.episode is Episode
    }

    func shareTapped(_ bookmark: Bookmark) {
        router?.bookmarkShare(bookmark)
    }

    func deleteTapped(_ bookmark: Bookmark) {
        confirmDeletion { [weak self] in
            self?.actuallyDelete([bookmark])
        }
    }

    func sorted(by option: BookmarkSortOption) {
        sortOption = option
        reload()
    }

    func deleteSelectedBookmarks() {
        let items = selectedItems
        guard !items.isEmpty else { return }

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

        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: sortOption.label, icon: "podcast-sort") { }
        sortAction.submenu = { [weak self] in self?.makeSortOptionsPicker() }

        optionPicker.addActions([
            .init(label: L10n.selectBookmarks, icon: "option-multiselect") { [weak self] in
                self?.toggleMultiSelection()
            },
            sortAction
        ])

        optionPicker.present()
    }

    func makeSortOptionsPicker() -> OptionsPicker {
        let optionPicker = OptionsPicker(title: L10n.sortBy)
        let currentSort = sortOption

        optionPicker.addActions(availableSortOptions.map({ option in
                .init(label: option.label, selected: option == currentSort) { [weak self] in
                self?.sorted(by: option)
            }
        }))

        return optionPicker
    }
}

private extension BookmarkListViewModel {
    func confirmDeletion(_ delete: @escaping () -> Void) {
        guard let router else { return }
        let source = analyticsSource
        let alert = UIAlertController(title: L10n.bookmarkDeleteWarningTitle,
                                      message: L10n.bookmarkDeleteWarningBody,
                                      preferredStyle: .alert)

        alert.addAction(.init(title: L10n.cancel, style: .cancel, handler: { _ in
            Analytics.track(.bookmarkDeleteFormDismissed, source: source)
        }))
        alert.addAction(.init(title: L10n.delete, style: .destructive, handler: { _ in
            Analytics.track(.bookmarkDeleteFormSubmitted, source: source)
            delete()
        }))
        Analytics.track(.bookmarkDeleteFormShown, source: analyticsSource)
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
