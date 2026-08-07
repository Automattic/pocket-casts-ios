import Combine
import PocketCastsDataModel
import SwiftUI
import UIKit

/// The page displaying the bookmarks tab: it shows the rows of the list in its table, presents the
/// screens the list opens, and mirrors its multi selection
@MainActor
protocol BookmarkListControllerDelegate: UIViewController, BookmarkListRouter {
    /// `true` while the bookmarks tab is the one on display
    var isBookmarkListDisplayed: Bool { get }

    /// Called when the search header appears or disappears, which changes the rows of the page
    func bookmarkListControllerDidChangeSearchVisibility(_ controller: BookmarkListController)

    /// Called when the multi selection of the list, or the bookmarks it selected, change
    func bookmarkListControllerDidChangeMultiSelection(_ controller: BookmarkListController)
}

/// The bookmarks tab of the podcast page.
///
/// It owns the list's view model and its search header, provides the cells the page displays in its
/// table, and presents the action bar of the multi selection.
@MainActor
final class BookmarkListController {
    /// The sections the list occupies in the page's table
    static let searchSection = 1
    static let listSection = 2

    let viewModel: BookmarkPodcastListViewModel

    /// The rows look the view model up by the type their environment declares
    private var listViewModel: BookmarkListViewModel { viewModel }

    /// `true` while the search header is displayed. It stays hidden until there's something to search.
    private(set) var showsSearch = false

    /// The overflow button is disabled while the page is in multi select
    var isOverflowButtonEnabled: Bool {
        get { searchController.isOverflowButtonEnabled }
        set { searchController.isOverflowButtonEnabled = newValue }
    }

    /// The search header, kept in its own cell so reloading the list doesn't take the keyboard
    /// focus away from the field
    private let searchController = EpisodeListSearchController()
    private let searchCell = UITableViewCell()

    private var rows: [Row] = []
    private let style = TransparentBookmarksStyle()

    private var actionBarHost: UIHostingController<AnyView>?
    private var actionBarBottomConstraint: NSLayoutConstraint?

    private weak var tableView: UITableView?
    private weak var delegate: BookmarkListControllerDelegate?

    private var cancellables = Set<AnyCancellable>()

    /// A row of the bookmarks list section
    private enum Row {
        case bookmark(Bookmark, showsDivider: Bool)
        case empty
    }

    init(podcast: Podcast, tableView: UITableView, delegate: BookmarkListControllerDelegate) {
        self.tableView = tableView
        self.delegate = delegate

        viewModel = BookmarkPodcastListViewModel(podcast: podcast,
                                                 bookmarkManager: PlaybackManager.shared.bookmarkManager,
                                                 sortOption: Settings.podcastBookmarksSort)
        viewModel.analyticsSource = .podcasts
        viewModel.router = delegate

        setupSearchController()
        rebuildRows()
        addListeners()
    }

    // MARK: - Search

    private func setupSearchController() {
        searchController.placeholder = L10n.searchBookmarks
        searchController.overflowAccessibilityLabel = L10n.bookmarks
        searchController.delegate = viewModel

        delegate?.addChild(searchController)
        searchController.didMove(toParent: delegate)

        searchCell.selectionStyle = .none
        searchCell.backgroundColor = .clear
        searchCell.contentView.addSubview(searchController.view)
        searchController.view.anchorToAllSidesOf(view: searchCell.contentView)
    }

    // MARK: - Rows

    /// The rows are driven by the view model, so reload them and the action bar as it changes
    private func addListeners() {
        Publishers.Merge3(viewModel.$items.map { _ in },
                          viewModel.$filteredItems.map { _ in },
                          viewModel.$isSearching.map { _ in })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadRows()
            }
            .store(in: &cancellables)

        viewModel.$searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.searchController.searchText = text
            }
            .store(in: &cancellables)

        Publishers.Merge3(viewModel.$isMultiSelecting.map { _ in },
                          viewModel.$selectedIDs.map { _ in },
                          viewModel.$items.map { _ in })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateActionBar()
            }
            .store(in: &cancellables)

        Publishers.Merge(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidAppear),
                         NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidDisappear))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateActionBarBottomConstraint()
            }
            .store(in: &cancellables)
    }

    /// Rebuilds the rows from the current state of the view model
    func rebuildRows() {
        showsSearch = viewModel.isSearching || viewModel.numberOfItems > 0
        searchController.info = NSAttributedString(string: L10n.bookmarkCount(viewModel.bookmarkCount),
                                                  attributes: [.foregroundColor: AppTheme.colorForStyle(.primaryText02)])

        let bookmarks = viewModel.bookmarks
        guard viewModel.feature.isUnlocked, !bookmarks.isEmpty else {
            rows = [.empty]
            return
        }

        rows = bookmarks.enumerated().map { index, bookmark -> Row in
            .bookmark(bookmark, showsDivider: index < bookmarks.count - 1)
        }
    }

    /// Reloads the list without touching the search field, so it keeps the keyboard focus while typing
    private func reloadRows() {
        guard let tableView, delegate?.isBookmarkListDisplayed == true,
              tableView.numberOfSections > Self.listSection else { return }

        let wasShowingSearch = showsSearch
        rebuildRows()

        guard wasShowingSearch == showsSearch else {
            delegate?.bookmarkListControllerDidChangeSearchVisibility(self)
            return
        }

        UIView.performWithoutAnimation {
            tableView.reloadSections(IndexSet(integer: Self.listSection), with: .none)
        }
    }

    // MARK: - Table Data

    static func registerCells(in tableView: UITableView) {
        for identifier in [CellID.bookmark, CellID.empty] {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: identifier)
        }
    }

    func numberOfRows(inSection section: Int) -> Int {
        if section == Self.searchSection {
            return showsSearch ? 1 : 0
        }
        return rows.count
    }

    /// The rows handle their own taps in SwiftUI, the selection is only there to highlight them
    func canSelectRow(at indexPath: IndexPath) -> Bool {
        bookmark(at: indexPath) != nil
    }

    private func bookmark(at indexPath: IndexPath) -> Bookmark? {
        guard indexPath.section == Self.listSection, case .bookmark(let bookmark, _) = rows[safe: indexPath.row] else { return nil }

        return bookmark
    }

    // MARK: - Swipe Actions

    /// Only the bookmark rows swipe, and only outside of the multi selection
    func canEditRow(at indexPath: IndexPath) -> Bool {
        !viewModel.isMultiSelecting && bookmark(at: indexPath) != nil
    }

    /// The same actions the SwiftUI list swipes in, rendered by the table
    func swipeActionsConfiguration(for edge: HorizontalEdge, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let bookmark = bookmark(at: indexPath) else { return nil }

        let actions = makeBookmarkSwipeActions(for: bookmark, edge: edge, viewModel: viewModel, style: style).map { action in
            let contextualAction = UIContextualAction(style: action.isDestructive ? .destructive : .normal, title: nil) { _, _, completion in
                action.handler()
                // The rows are reloaded by the view model, so the table shouldn't remove them itself
                completion(false)
            }
            contextualAction.image = UIImage(named: action.imageName)
            contextualAction.backgroundColor = UIColor(action.tint)
            contextualAction.accessibilityLabel = action.title
            return contextualAction
        }

        guard !actions.isEmpty else { return nil }

        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    // MARK: - Cells

    func cell(_ tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Self.searchSection {
            return searchCell
        }

        guard let row = rows[safe: indexPath.row] else { return UITableViewCell() }

        switch row {
        case .bookmark(let bookmark, let showsDivider):
            let cell = hostingCell(tableView, identifier: CellID.bookmark, at: indexPath) {
                VStack(spacing: 0) {
                    BookmarkRow(bookmark: bookmark, style: style)

                    if showsDivider {
                        HairlineSeparator(color: style.divider)
                    }
                }
                .environmentObject(listViewModel)
                // The hosting configuration reuses its view, and with it the row's state
                .id(bookmark.uuid)
            }
            let selectedBackground = cell.selectedBackgroundView ?? UIView()
            selectedBackground.backgroundColor = AppTheme.colorForStyle(.primaryUi02Active)
            cell.selectedBackgroundView = selectedBackground
            cell.selectionStyle = .default
            return cell

        case .empty:
            return hostingCell(tableView, identifier: CellID.empty, at: indexPath) {
                BookmarksEmptyRow(viewModel: listViewModel, style: style, feature: viewModel.feature)
                    .padding(.top, showsSearch ? 0 : BookmarksTabConstants.emptyRowTopPadding)
                    .environmentObject(listViewModel)
            }
        }
    }

    private func hostingCell<Content: View>(_ tableView: UITableView, identifier: String, at indexPath: IndexPath, @ViewBuilder content: () -> Content) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = UIHostingConfiguration(content: content).margins(.all, 0)
        return cell
    }

    // MARK: - Action Bar

    /// Mirrors the multi selection of the list: the page displays the navigation bar of its own multi
    /// select and the list displays its action bar
    func updateActionBar() {
        delegate?.bookmarkListControllerDidChangeMultiSelection(self)

        // Without any selected items there's nothing to act on
        let selectedCount = viewModel.selectedItems.count
        guard viewModel.isMultiSelecting, selectedCount > 0 else {
            removeActionBar()
            return
        }

        let actions: [ActionBarView<ThemedActionBarStyle>.Action] = makeBookmarkActions(viewModel: viewModel)
        actionBar()?.rootView = AnyView(
            ActionBarView(title: L10n.selectedCountFormat(selectedCount), style: ThemedActionBarStyle(), actions: actions)
                .padding(.bottom) // match internal spacing
        )
    }

    func removeActionBar() {
        guard let host = actionBarHost else { return }

        host.willMove(toParent: nil)
        host.view.removeFromSuperview()
        host.removeFromParent()
        actionBarHost = nil
        actionBarBottomConstraint = nil
    }

    /// The action bar sits on the page's view so it can float above the mini player
    private func actionBar() -> UIHostingController<AnyView>? {
        if let actionBarHost { return actionBarHost }

        guard let delegate else { return nil }

        let host = UIHostingController(rootView: AnyView(EmptyView()))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false

        delegate.addChild(host)
        delegate.view.addSubview(host.view)

        let bottom = host.view.bottomAnchor.constraint(equalTo: delegate.view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.effectiveMiniPlayerOffset)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: delegate.view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: delegate.view.trailingAnchor),
            bottom
        ])
        host.didMove(toParent: delegate)

        actionBarHost = host
        actionBarBottomConstraint = bottom
        return host
    }

    private func updateActionBarBottomConstraint() {
        guard let actionBarBottomConstraint, let delegate else { return }

        actionBarBottomConstraint.constant = -Constants.effectiveMiniPlayerOffset
        UIView.animate(withDuration: 0.1) { delegate.view.layoutIfNeeded() }
    }
}

// MARK: - EpisodeListSearchControllerDelegate

/// The bookmarks tab drives its search header straight from the list view model, which debounces
/// the term and filters the bookmarks itself
extension BookmarkPodcastListViewModel: EpisodeListSearchControllerDelegate {
    func episodeListSearchController(_ controller: EpisodeListSearchController, didChangeSearchTerm searchTerm: String) {
        if searchTerm.isEmpty {
            cancelSearch()
        } else {
            searchText = searchTerm
        }
    }

    func episodeListSearchControllerDidTapOverflow(_ controller: EpisodeListSearchController) {
        showMoreOptions()
    }
}

// MARK: - Rows

/// A bookmarks style that lets the podcast page background show through
class TransparentBookmarksStyle: ThemedBookmarksStyle {
    override var background: Color { Color.clear }
}

/// Displayed instead of the list when there's nothing to show
private struct BookmarksEmptyRow<Style: BookmarksStyle>: View {
    @ObservedObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: Style
    @ObservedObject var feature: PaidFeature

    var body: some View {
        if !feature.isUnlocked {
            BookmarksLockedStateView(style: style.emptyStyle, feature: feature, source: viewModel.analyticsSource)
        } else if !viewModel.isSearching {
            BookmarksEmptyStateView(style: style.emptyStyle)
        } else {
            BookmarksEmptyStateView(style: .defaultStyle,
                                    title: L10n.bookmarkSearchNoResultsTitle,
                                    message: L10n.bookmarkSearchNoResultsMessage,
                                    actionTitle: L10n.clearSearch) {
                viewModel.cancelSearch()
            }
        }
    }
}

private enum CellID {
    static let bookmark = "BookmarkCell"
    static let empty = "BookmarksEmptyCell"
}

private enum BookmarksTabConstants {
    static let emptyRowTopPadding = 10.0
}
