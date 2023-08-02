import SwiftUI

struct BookmarksPodcastListView: View {
    @ObservedObject var viewModel: BookmarkPodcastListViewModel
    @ObservedObject var style = ThemedBookmarksStyle()

    var body: some View {
        VStack(spacing: BookmarkListConstants.padding) {
            headerView
            bookmarkListView
        }
        .background(style.background.ignoresSafeArea())
    }

    /// Shows the title and search field
    private var headerView: some View {
        VStack(spacing: Constants.padding) {
            ZStack {
                BookmarkCardTitleView(viewModel: viewModel, style: style)
                BookmarkListMultiSelectHeaderView(viewModel: viewModel, style: style)
            }
            .animation(.linear(duration: 0.2), value: viewModel.isMultiSelecting)

            searchField
        }
        .padding(.top, Constants.padding)
        .padding(.horizontal, BookmarkListConstants.padding)
    }

    @ViewBuilder
    private var searchField: some View {
        if viewModel.isSearching || !viewModel.bookmarks.isEmpty {
            SearchField(text: $viewModel.searchText)
                .disabled(viewModel.isMultiSelecting)
        }
    }

    private var bookmarkListView: some View {
        VStack(spacing: BookmarkListConstants.headerPadding) {
            // The list view doesn't show a divider at the top of the heading, so we add it here
            // Unless we're showing the empty view
            if viewModel.bookmarkCount > 0 {
                Divider().background(style.divider)
            }

            BookmarksListView(viewModel: viewModel, style: style, showMultiSelectInHeader: false)
        }
    }

    private enum Constants {
        static let padding = 14.0
    }
}
