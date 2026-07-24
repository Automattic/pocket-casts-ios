import SwiftUI
import PocketCastsUtils

struct BookmarksProfileListView: View {
    @ObservedObject var viewModel: BookmarkPodcastListViewModel
    @ObservedObject var style = ThemedBookmarksStyle()

    var body: some View {
        VStack(spacing: BookmarkListConstants.padding) {
            searchField
                .padding([.horizontal], BookmarkListConstants.headerPadding)
                .background(style.theme.secondaryUi01)
            bookmarkListView
        }
        .navigationTitle(L10n.bookmarks)
        .navigationBarBackButtonHidden(viewModel.isMultiSelecting)
        .toolbar {
            toolbar
        }
        .background(style.background.ignoresSafeArea())
    }

    private var navBarTint: Color? {
        ThemeColor.navBarTint(ThemeColor.secondaryIcon01(for: style.theme.activeTheme))
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if viewModel.isMultiSelecting {
                Button {
                    viewModel.toggleSelectAll()
                } label: {
                    if viewModel.hasSelectedAll {
                        Text(L10n.deselectAll)
                    } else {
                        Text(L10n.selectAll)
                    }
                }
                .tint(navBarTint)
            }
        }

        if viewModel.bookmarks.isEmpty == false {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if viewModel.isMultiSelecting {
                        viewModel.toggleMultiSelection()
                    } else {
                        viewModel.showMoreOptions()
                    }
                } label: {
                    if viewModel.isMultiSelecting {
                        Text(L10n.cancel)
                    } else {
                        Image("more")
                    }
                }
                .disabled(!viewModel.feature.isUnlocked)
                .opacity(viewModel.feature.isUnlocked ? 1 : 0)
                .tint(navBarTint)
            }
        }
    }

    @ViewBuilder
    private var searchField: some View {
        if viewModel.isSearching || !viewModel.bookmarks.isEmpty {
            SearchField(text: $viewModel.searchText)
                .disabled(viewModel.isMultiSelecting)
        }
    }

    private var bookmarkListView: some View {
        BookmarksListView(viewModel: viewModel, style: style, showHeader: false, showMultiSelectInHeader: false, showMoreInHeader: false)
    }
}
