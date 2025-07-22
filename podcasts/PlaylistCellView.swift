import SwiftUI
import PocketCastsDataModel

struct PlaylistCellView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistCellViewModel

    var body: some View {
        HStack(spacing: 16.0) {
            PlaylistArtworkView(urls: viewModel.imageURLs, size: 168)
                .frame(width: 56.0, height: 56.0)
                .padding(.leading, 16.0)
            VStack(alignment: .leading) {
                Text(viewModel.playListName())
                    .foregroundStyle(theme.primaryText01)
                    .font(size: 15.0, style: .body, weight: .medium)
                if viewModel.isSmartPlaylist() {
                    Text("Smart Playlist")
                        .foregroundStyle(theme.primaryText02)
                        .font(size: 14.0, style: .body, weight: .regular)
                }
            }
            Spacer()
            HStack(spacing: 5.0) {
                Text("\(viewModel.episodesCount)")
                    .foregroundStyle(theme.primaryText02)
                    .font(size: 14.0, style: .body, weight: .regular)
            }
            .padding(.trailing, 8.0)
        }
        .background(.clear)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @EnvironmentObject var theme: Theme
        private let vm1 = PlaylistCellViewModel()
        private let vm2 = PlaylistCellViewModel()

        var body: some View {
            List {
                PlaylistCellView(
                    viewModel: vm1
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)

                PlaylistCellView(
                    viewModel: vm2
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)
            }
            .onAppear {
                vm1.set(playlist: model())
                vm2.set(playlist: model())
            }
        }

        private func model() -> EpisodeFilter {
            let filter = EpisodeFilter()
            filter.rawPlaylistType = 0
            filter.playlistName = "New Releases"
            return filter
        }
    }
    return PreviewWrapper()
        .environmentObject(Theme.sharedTheme)
}
