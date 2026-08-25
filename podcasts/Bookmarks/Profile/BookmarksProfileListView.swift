import SwiftUI
import PocketCastsUtils

struct BookmarksProfileListView: View {
    @ObservedObject var viewModel: BookmarkPodcastListViewModel
    @ObservedObject var style = FullScreenBookmarksStyle()
    @ObservedObject private var searchTheme = BookmarksSearchFieldTheme()

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding([.horizontal], BookmarkListConstants.headerPadding)
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
            SearchField(theme: searchTheme, text: $viewModel.searchText)
                .disabled(viewModel.isMultiSelecting)
        }
    }

    private var bookmarkListView: some View {
        BookmarksListView(viewModel: viewModel, style: style, showHeader: false, showMultiSelectInHeader: false, showMoreInHeader: false)
            .padding(.top, BookmarkListConstants.padding)
    }
}

private final class BookmarksSearchFieldTheme: SearchField.SearchTheme {
    override var background: Color { theme.primaryField01 }
    override var placeholder: Color { theme.primaryText02 }
    override var text: Color { theme.primaryText01 }
    override var cancel: Color { theme.primaryText01 }
    override var icon: Color { theme.primaryIcon02 }
}
