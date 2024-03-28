import SwiftUI

struct FilesListView: View {
    @StateObject var viewModel = FilesListViewModel()
    var body: some View {
        ItemListContainer(isEmpty: $viewModel.episodes.isEmpty, loading: viewModel.isLoading) {
            List {
                EpisodeListView(title: L10n.settingsFiles.prefixSourceUnicode, showArtwork: true, episodes: $viewModel.episodes, playlist: .files)
                .withOrderPickerToolbar(selectedOption: viewModel.sortOrder, title: L10n.filesSort, supportsToolbar: viewModel.supportsSort) { option in
                        viewModel.sortOrder = option
                    }
            }
        }
        .navigationTitle(L10n.settingsFiles.prefixSourceUnicode)
        .onAppear {
            viewModel.loadUserEpisodes()
        }
    }
}

struct FilesListView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(PreviewDevice.previewDevices) {
            FilesListView()
                .previewDevice($0)
        }
    }
}
