import SwiftUI

struct BookmarkEpisodeListView: View {
    @ObservedObject var viewModel: BookmarkEpisodeListViewModel

    var body: some View {
        BookmarksListView(viewModel: viewModel, style: ThemedBookmarksStyle())
    }
}
