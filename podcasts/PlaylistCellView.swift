import SwiftUI
import PocketCastsDataModel

struct PlaylistCellView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistCellViewModel

    @Binding private var isSelected: Bool

    init(
        viewModel: PlaylistCellViewModel,
        isSelected: Binding<Bool> = .constant(false)
    ) {
        self.viewModel = viewModel
        self._isSelected = isSelected
    }

    var body: some View {
        HStack(spacing: 16.0) {
            PlaylistArtworkView(items: viewModel.images, imageSize: 168)
                .frame(width: 56.0, height: 56.0)
                .padding(.leading, 16.0)
            VStack(alignment: .leading, spacing: 2.0) {
                Text(viewModel.playListName())
                    .foregroundStyle(theme.primaryText01)
                    .font(size: 15.0, style: .body, weight: .medium)
                if viewModel.isSmartPlaylist() {
                    Text(L10n.smartPlaylist)
                        .foregroundStyle(theme.primaryText02)
                        .font(size: 14.0, style: .body, weight: .regular)
                }
            }
            Spacer()
            switch viewModel.displayType {
            case .count:
                HStack(spacing: 5.0) {
                    Text("\(viewModel.episodesCount)")
                        .foregroundStyle(theme.primaryText02)
                        .font(size: 14.0, style: .body, weight: .regular)
                }
                .padding(.trailing, 8.0)
            case .toggle:
                Toggle("", isOn: $isSelected)
                    .labelsHidden()
                    .tint(theme.primaryInteractive01)
                    .padding(.trailing, 16.0)
            case .check, .addNew:
                EmptyView()
            }
        }
        .background(.clear)
        .onAppear {
            viewModel.loadData()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @EnvironmentObject var theme: Theme

        var body: some View {
            List {
                PlaylistCellView(
                    viewModel: PlaylistCellViewModel(playlist: model())
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)

                PlaylistCellView(
                    viewModel: PlaylistCellViewModel(
                        playlist: model(),
                        displayType: .toggle
                    ),
                    isSelected: .constant(true)
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)
            }
        }

        private func model() -> EpisodeFilter {
            let filter = EpisodeFilter()
            filter.playlistName = "New Releases"
            return filter
        }
    }
    return PreviewWrapper()
        .environmentObject(Theme.sharedTheme)
}
