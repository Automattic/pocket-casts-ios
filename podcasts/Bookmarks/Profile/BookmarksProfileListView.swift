import SwiftUI
import PocketCastsUtils

struct BookmarksProfileListView: View {
    @ObservedObject var viewModel: BookmarkPodcastListViewModel
    @ObservedObject var style = ThemedBookmarksStyle()

    var body: some View {
        VStack(spacing: BookmarkListConstants.padding) {
            searchField.padding([.top, .horizontal], BookmarkListConstants.headerPadding)
            bookmarkListView
        }
        .navigationTitle(L10n.bookmarks)
        .navigationBarBackButtonHidden(viewModel.isMultiSelecting)
        .toolbar {
            toolbar
        }
        .background(style.background.ignoresSafeArea())
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
                .tint(style.theme.secondaryIcon01)
            }
        }
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
            .tint(style.theme.secondaryIcon01)
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
            .padding(.bottom, bottomInset(multiSelectEnabled: viewModel.isMultiSelecting))
    }

    func bottomInset(multiSelectEnabled: Bool) -> CGFloat {
        let multiSelectFooterOffset: CGFloat = multiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        return min(miniPlayerOffset + multiSelectFooterOffset, 40)
    }
}
