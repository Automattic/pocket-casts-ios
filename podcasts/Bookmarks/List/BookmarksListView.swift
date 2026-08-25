import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarksListView<ListStyle: BookmarksStyle>: View {
    @ObservedObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: ListStyle
    @ObservedObject private var feature: PaidFeature

    var showHeader: Bool = true
    /// When true, when entering multiselect the select all/cancel buttons will appear over the heading view
    /// Set this to false to implement custom handling
    var showMultiSelectInHeader: Bool = true

    var showMoreInHeader: Bool = true

    // When false, the action bar won't reserve space for the mini player below it.
    // Set this for hosts where the mini player never appears, like the full screen player.
    var reservesMiniPlayerSpace: Bool = true

    init(viewModel: BookmarkListViewModel,
         style: ListStyle,
         showHeader: Bool = true,
         showMultiSelectInHeader: Bool = true,
         showMoreInHeader: Bool = true,
         reservesMiniPlayerSpace: Bool = true) {
        self.viewModel = viewModel
        self.feature = viewModel.feature
        self.style = style
        self.showHeader = showHeader
        self.showMultiSelectInHeader = showMultiSelectInHeader
        self.showMoreInHeader = showMoreInHeader
        self.reservesMiniPlayerSpace = reservesMiniPlayerSpace
    }

    private var actionBarVisible: Bool {
        viewModel.isMultiSelecting && !viewModel.selectedItems.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if !feature.isUnlocked || viewModel.bookmarks.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .environmentObject(viewModel)
    }

    /// An empty state view that displays instructions
    @ViewBuilder
    private var emptyView: some View {
        Spacer()

        if !feature.isUnlocked {
            BookmarksLockedStateView(style: style.emptyStyle, feature: feature, source: viewModel.analyticsSource)
        }
        else if !viewModel.isSearching {
            BookmarksEmptyStateView(style: style.emptyStyle)
        } else {
            noSearchResultsView
        }

        Spacer()
    }

    private var noSearchResultsView: some View {
        BookmarksEmptyStateView(style: .defaultStyle,
                                title: L10n.bookmarkSearchNoResultsTitle,
                                message: L10n.bookmarkSearchNoResultsMessage,
                                actionTitle: L10n.clearSearch) {
            viewModel.cancelSearch()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if showHeader {
            headerView
            divider
        }

        if LiquidGlass.isEnabled {
            scrollView
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if actionBarVisible {
                        ActionBarView(
                            title: L10n.selectedCountFormat(viewModel.selectedItems.count),
                            style: style.actionBarStyle,
                            actions: bookmarkActions
                        )
                        .transition(.opacity)
                    }
                }
                .animation(.linear(duration: 0.1), value: actionBarVisible)
                .enclosingTabBarHidden(viewModel.isMultiSelecting)
        } else {
            // `ActionBarOverlayView` is used on iOS 18 and earlier only.
            ActionBarOverlayView(actionBarVisible: actionBarVisible,
                                 title: L10n.selectedCountFormat(viewModel.selectedItems.count),
                                 style: style.actionBarStyle,
                                 content: { scrollView },
                                 actions: bookmarkActions,
                                 reservesMiniPlayerSpace: reservesMiniPlayerSpace)
        }
    }

    /// A static header view that displays the number of bookmarks and a ... more button
    @ViewBuilder
    private var headerView: some View {
        // Using a ZStack here to prevent the header from changing height when switching between modes
        ZStack {
            let isMultiSelecting = showMultiSelectInHeader && viewModel.isMultiSelecting

            HStack {
                Text(L10n.bookmarkCount(viewModel.bookmarkCount))
                    .foregroundStyle(style.secondaryText)
                    .font(size: 14, style: .subheadline)

                Spacer()

                if showMoreInHeader {
                    Image("more").foregroundStyle(style.primaryText).buttonize {
                        viewModel.showMoreOptions()
                    }
                }
            }
            .opacity(isMultiSelecting ? 0 : 1)
            .offset(y: isMultiSelecting ? BookmarkListConstants.headerTransitionOffset : 0)

            if showMultiSelectInHeader {
                BookmarkListMultiSelectHeaderView(viewModel: viewModel, style: style)
            }
        }
        .padding(.horizontal, BookmarkListConstants.padding)
        .padding(.bottom, BookmarkListConstants.headerPadding)
    }

    @ViewBuilder
    private var scrollView: some View {
        List {
            bookmarksRows
        }
        .animation(.default, value: viewModel.bookmarks.map(\.id))
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(style.listBackground)
        .environment(\.defaultMinListRowHeight, 0)
    }

    @ViewBuilder
    private var bookmarksRows: some View {
        ForEach(viewModel.bookmarks) { bookmark in
            bookmarkRow(bookmark)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            if !viewModel.isLast(item: bookmark) {
                divider
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        if !LiquidGlass.isEnabled && actionBarVisible {
            Spacer(minLength: BookmarkListConstants.multiSelectionBottomPadding)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        BookmarkRow(bookmark: bookmark, style: style)
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                swipeActions(for: bookmark, edge: .leading)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                swipeActions(for: bookmark, edge: .trailing)
            }
    }

    private func swipeActions(for bookmark: Bookmark, edge: HorizontalEdge) -> some View {
        ForEach(makeBookmarkSwipeActions(for: bookmark, edge: edge, viewModel: viewModel, style: style)) { action in
            Button(role: action.isDestructive ? .destructive : nil) {
                action.handler()
            } label: {
                Image(action.imageName)
            }
            .tint(action.tint)
            .accessibilityLabel(action.title)
        }
    }

    private var bookmarkActions: [ActionBarView<ListStyle.ActionStyle>.Action] {
        makeBookmarkActions(viewModel: viewModel)
    }

    // MARK: - Utility Views

    /// Styled divider view
    @ViewBuilder
    private var divider: some View {
        HairlineSeparator(color: style.divider)
    }
}

/// A header view that appears when we're in the multi selection mode
struct BookmarkListMultiSelectHeaderView<HeaderStyle: BookmarksStyle>: View {
    @ObservedObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: HeaderStyle

    var body: some View {
        HStack {
            Button(viewModel.hasSelectedAll ? L10n.deselectAll : L10n.selectAll) {
                viewModel.toggleSelectAll()
            }

            Spacer()

            Button(L10n.cancel) {
                withAnimation {
                    viewModel.toggleMultiSelection()
                }
            }
        }
        .font(style: .body)
        .foregroundStyle(style.titleText)
        .opacity(viewModel.isMultiSelecting ? 1 : 0)
        .offset(y: viewModel.isMultiSelecting ? 0 : -BookmarkListConstants.headerTransitionOffset)
    }
}

enum BookmarkListConstants {
    static let padding = 16.0
    static let headerPadding = 16.0
    static let headerTransitionOffset = 10.0
    static let multiSelectionBottomPadding = 70.0
}

// MARK: - Previews

struct BookmarksListView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksListView(viewModel: .init(bookmarkManager: .init(), sortOption: Binding.constant(BookmarkSortOption.newestToOldest)), style: BookmarksPlayerTabStyle())
            .setupDefaultEnvironment()
    }
}
