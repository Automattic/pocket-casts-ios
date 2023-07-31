import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarksPlayerTab: View {
    @ObservedObject var viewModel: BookmarkEpisodeListViewModel

    var body: some View {
        BookmarksListView(viewModel: viewModel, style: BookmarksPlayerTabStyle())
            .padding(.bottom)
    }
}

// MARK: - Previews

struct BookmarksPlayerTab_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksPlayerTab(viewModel: .init(bookmarkManager: .init(), sortOption: .init("", defaultValue: .newestToOldest)))
            .setupDefaultEnvironment()
    }
}
