import SwiftUI
import PocketCastsUtils

struct BookmarksAccountListView: View {
    @ObservedObject var viewModel: BookmarkPodcastListViewModel
    @ObservedObject var style = ThemedBookmarksStyle()

    var body: some View {
        VStack(spacing: BookmarkListConstants.padding) {
            headerView
            bookmarkListView
        }
        .navigationTitle(L10n.bookmarks)        
        .background(style.background.ignoresSafeArea())
    }

    /// Shows the title and search field
    private var headerView: some View {
        searchField.padding()
    }

    @ViewBuilder
    private var searchField: some View {
        if viewModel.isSearching || !viewModel.bookmarks.isEmpty {
            SearchField(text: $viewModel.searchText)
                .disabled(viewModel.isMultiSelecting)
        }
    }

    private var bookmarkListView: some View {
        VStack {
            BookmarksListView(viewModel: viewModel, style: style, showHeader: false, showMultiSelectInHeader: false, showMoreInHeader: false)
        }.padding(.bottom, bottomInset(multiSelectEnabled: false))
    }

    func bottomInset(multiSelectEnabled: Bool) -> CGFloat {
        let multiSelectFooterOffset: CGFloat = multiSelectEnabled ? 80 : 0
        let miniPlayerOffset: CGFloat = PlaybackManager.shared.currentEpisode() == nil ? 0 : Constants.Values.miniPlayerOffset
        return min(miniPlayerOffset + multiSelectFooterOffset, 40)
    }
}
