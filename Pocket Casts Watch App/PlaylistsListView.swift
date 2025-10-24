import SwiftUI
import PocketCastsUtils

struct PlaylistsListView: View {
    @StateObject var viewModel = PlaylistsListViewModel()

    var body: some View {
        ItemListContainer(isEmpty: viewModel.playlists.isEmpty, noItemsTitle: FeatureFlag.playlistsRebranding.enabled ? L10n.watchNoPlaylists : L10n.watchNoFilters, loading: viewModel.isLoading) {
            List {
                ForEach(viewModel.playlists, id: \.uuid) { filter in
                    NavigationLink(destination: FilterEpisodeListView(viewModel: FilterEpisodeListViewModel(filter: filter))) {
                        MenuRow(label: filter.title, icon: filter.iconName ?? "filter_list", count: viewModel.episodeCount(for: filter))
                    }
                }
            }
        }
        .navigationTitle(FeatureFlag.playlistsRebranding.enabled ? L10n.playlists.prefixSourceUnicode : L10n.filters.prefixSourceUnicode)
        .restorable(.filterList)
        .onAppear {
            viewModel.loadData()
        }
    }
}

#Preview {
    PlaylistsListView()
}
