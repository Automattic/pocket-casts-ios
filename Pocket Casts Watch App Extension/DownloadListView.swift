import SwiftUI

struct DownloadListView: View {
    @StateObject var viewModel = DownloadListViewModel()
    var body: some View {
        ItemListContainer(isEmpty: viewModel.episodes.isEmpty, loading: viewModel.isLoading) {
            ScrollView {
                LazyVStack {
                    EpisodeListView(title: L10n.Localizable.podcastsPlural.prefixSourceUnicode, showArtwork: true, episodes: $viewModel.episodes)
                }
            }
        }
        .navigationTitle(L10n.Localizable.downloads.prefixSourceUnicode)
        .onAppear {
            viewModel.loadEpisodes()
        }
    }
}

struct DownloadListView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadListView(viewModel: DownloadListViewModel())
    }
}
