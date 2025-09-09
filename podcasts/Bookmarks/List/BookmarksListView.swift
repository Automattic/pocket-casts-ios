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

    var allowInternalScrolling: Bool = true

    // When true, the SwiftUI overlay bar will not be rendered; instead we notify
    // an external presenter (e.g., PodcastViewController) to show the bar.
    var useExternalActionBar: Bool = false

    // Callback to inform an external presenter of the desired action bar state
    var externalActionBarHandler: ((ExternalActionBarState) -> Void)? = nil

    @State private var showShadow = false

    init(viewModel: BookmarkListViewModel,
         style: ListStyle,
         showHeader: Bool = true,
         showMultiSelectInHeader: Bool = true,
         showMoreInHeader: Bool = true,
         allowInternalScrolling: Bool = true,
         useExternalActionBar: Bool = false,
         externalActionBarHandler: ((ExternalActionBarState) -> Void)? = nil) {
        self.viewModel = viewModel
        self.feature = viewModel.feature
        self.style = style
        self.showHeader = showHeader
        self.showMultiSelectInHeader = showMultiSelectInHeader
        self.showMoreInHeader = showMoreInHeader
        self.allowInternalScrolling = allowInternalScrolling
        self.useExternalActionBar = useExternalActionBar
        self.externalActionBarHandler = externalActionBarHandler
    }

    private var actionBarVisible: Bool {
        viewModel.isMultiSelecting && viewModel.numberOfSelectedItems > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            if !feature.isUnlocked || viewModel.bookmarks.isEmpty {
                emptyView
            } else {
                listView
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

    /// The main content view that displays a list of bookmarks
    @ViewBuilder
    private var listView: some View {
        if showHeader {
            headerView
            divider
        }

        actionBarView {
            Group {
                if allowInternalScrolling {
                    scrollView
                } else {
                    stableContainer
                }
            }
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
        ZStack(alignment: .top) {
            ScrollViewWithContentOffset {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.bookmarks) { bookmark in
                        BookmarkRow(bookmark: bookmark, style: style)

                        if !viewModel.isLast(item: bookmark) {
                            divider
                        }
                    }

                    // Add padding to the bottom of the list when the action bar is visible so it's not blocking the view
                    if actionBarVisible {
                        Spacer(minLength: BookmarkListConstants.multiSelectionBottomPadding)
                    }
                }
            }
            .onContentOffsetChange { contentOffset in
                showShadow = Int(contentOffset.y) < 0
            }

            // Shadow overlay
            shadowView
        }
    }

    private var stableContainer: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.bookmarks) { bookmark in
                    BookmarkRow(bookmark: bookmark, style: style)

                    if !viewModel.isLast(item: bookmark) {
                        divider
                    }
                }

                // Add padding to the bottom of the list when the action bar is visible so it's not blocking the view
                if actionBarVisible {
                    Spacer(minLength: BookmarkListConstants.multiSelectionBottomPadding)
                }
            }
        }
        .scrollDisabled(true)
    }

    @ViewBuilder
    private var listContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.bookmarks) { bookmark in
                BookmarkRow(bookmark: bookmark, style: style)

                if !viewModel.isLast(item: bookmark) {
                    divider
                }
            }

            // Add padding to the bottom of the list when the action bar is visible so it's not blocking the view
            if actionBarVisible {
                Spacer(minLength: BookmarkListConstants.multiSelectionBottomPadding)
            }
        }
    }

    @ViewBuilder
    private func actionBarView<Content: View>(_ content: @escaping () -> Content) -> some View {
        let title = L10n.selectedCountFormat(viewModel.numberOfSelectedItems)
        let editVisible = viewModel.numberOfSelectedItems == 1
        let shareVisible = viewModel.selectedItems.first?.episode is Episode
        Group {
            if useExternalActionBar {
                content()
                    .onAppear { notifyExternalActionBar(title: title, editVisible: editVisible, shareVisible: shareVisible) }
                    .onChange(of: viewModel.numberOfSelectedItems) { _ in
                        notifyExternalActionBar(title: L10n.selectedCountFormat(viewModel.numberOfSelectedItems), editVisible: viewModel.numberOfSelectedItems == 1, shareVisible: viewModel.selectedItems.first?.episode is Episode)
                    }
                    .onChange(of: viewModel.isMultiSelecting) { _ in
                        notifyExternalActionBar(title: L10n.selectedCountFormat(viewModel.numberOfSelectedItems), editVisible: viewModel.numberOfSelectedItems == 1, shareVisible: viewModel.selectedItems.first?.episode is Episode)
                    }
                    .onDisappear {
                        externalActionBarHandler?(ExternalActionBarState(visible: false, title: nil, showEdit: false, showShare: false, isMultiSelecting: false))
                    }
            } else {
                ActionBarOverlayView(actionBarVisible: actionBarVisible, title: title, style: style.actionBarStyle, content: {
                    content()
                }, actions: [
                    .init(imageName: "podcast-share", title: L10n.share, visible: editVisible && shareVisible, action: {
                        viewModel.shareSelectedBookmarks()
                    }),
                    .init(imageName: "folder-edit", title: L10n.edit, visible: editVisible, action: {
                        viewModel.editSelectedBookmarks()
                    }),
                    .init(imageName: "delete", title: L10n.delete, action: {
                        viewModel.deleteSelectedBookmarks()
                    })
                ])
            }
        }
    }

    // MARK: - Utility Views

    /// A shadow view that adds depth between the scroll view and the static header
    private var shadowView: some View {
        LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0)], startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity, maxHeight: BookmarkListConstants.shadowHeight)
            .opacity(showShadow ? 1 : 0)
            .animation(.linear(duration: 0.2), value: showShadow)
    }

    /// Styled divider view
    @ViewBuilder
    private var divider: some View {
        Divider().background(style.divider)
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
    static let shadowHeight = 20.0
    static let padding = 16.0
    static let headerPadding = 12.0
    static let headerTransitionOffset = 10.0
    static let multiSelectionBottomPadding = 70.0
}

// Represents the current desired state for an externally presented action bar
struct ExternalActionBarState {
    let visible: Bool
    let title: String?
    let showEdit: Bool
    let showShare: Bool
    let isMultiSelecting: Bool
}

private extension BookmarksListView {
    func notifyExternalActionBar(title: String, editVisible: Bool, shareVisible: Bool) {
        guard useExternalActionBar else { return }
        externalActionBarHandler?(ExternalActionBarState(visible: actionBarVisible,
                                                         title: actionBarVisible ? title : nil,
                                                         showEdit: actionBarVisible && editVisible,
                                                         showShare: actionBarVisible && editVisible && shareVisible,
                                                         isMultiSelecting: viewModel.isMultiSelecting))
    }
}

// MARK: - Previews

struct BookmarksListView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksListView(viewModel: .init(bookmarkManager: .init(), sortOption: Binding.constant(BookmarkSortOption.newestToOldest)), style: BookmarksPlayerTabStyle())
            .setupDefaultEnvironment()
    }
}
