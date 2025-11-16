import SwiftUI
import PocketCastsDataModel

struct NewPlaylistCellView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: NewPlaylistCellViewModel

    @State private var refreshToken = UUID()

    private var title: String {
        switch viewModel.displayType {
        case .addNew:
            return L10n.playlistsDefaultNewPlaylist
        default:
            return viewModel.playlistName
        }
    }

    private var subtitle: String? {
        switch viewModel.displayType {
        case .check:
            return L10n.playlistEpisodesCount(viewModel.episodesCount)
        case .toggle, .count, .plain:
            if viewModel.isSmartPlaylist {
                return L10n.smartPlaylist
            }
            return nil
        default:
            return nil
        }
    }

    init(
        viewModel: NewPlaylistCellViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: 16.0) {
            if viewModel.displayType == .addNew {
                ZStack {
                    Rectangle()
                        .foregroundColor(theme.primaryUi05)
                    Image("add-playlist")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryInteractive01)
                }
                .cornerRadius(4)
                .clipped()
                .frame(width: 56.0, height: 56.0)
                .padding(.leading, 16.0)
            } else {
                PlaylistArtworkView(items: viewModel.images)
                    .frame(width: 56.0, height: 56.0)
                    .padding(.leading, 16.0)
            }
            VStack(alignment: .leading, spacing: 2.0) {
                Text(title)
                    .foregroundStyle(theme.primaryText01)
                    .font(size: 15.0, style: .body, weight: .medium)
                if let subtitle {
                    subtitleView(text: subtitle)
                }
            }
            Spacer()
            accesoryView()
        }
        .background(.clear)
    }

    private func subtitleView(text: String) -> some View {
        Text(text)
            .foregroundStyle(theme.primaryText02)
            .font(size: 14.0, style: .body, weight: .regular)
    }

    @ViewBuilder private func accesoryView() -> some View {
        switch viewModel.displayType {
        case .count:
            HStack(spacing: 5.0) {
                subtitleView(text: "\(viewModel.episodesCount)")
            }
            .padding(.trailing, 8.0)
        default:
            EmptyView()
        }
    }
}

//#Preview {
//    struct PreviewWrapper: View {
//        @EnvironmentObject var theme: Theme
//
//        var body: some View {
//            List {
//                NewPlaylistCellView(
//                    viewModel: NewPlaylistCellViewModel(
//                        playlist: model(),
//                        displayType: .plain
//                    ),
//                    isSelected: .constant(true)
//                )
//                .frame(width: 350, height: 81)
//                .background(.white)
//                .listRowSeparator(.hidden)
//
//                NewPlaylistCellView(
//                    viewModel: NewPlaylistCellViewModel(
//                        playlist: model(),
//                        displayType: .addNew
//                    ),
//                    isSelected: .constant(true)
//                )
//                .frame(width: 350, height: 81)
//                .background(.white)
//                .listRowSeparator(.hidden)
//
//                NewPlaylistCellView(
//                    viewModel: NewPlaylistCellViewModel(playlist: model(), displayType: .count)
//                )
//                .frame(width: 350, height: 81)
//                .background(.white)
//                .listRowSeparator(.hidden)
//
//                NewPlaylistCellView(
//                    viewModel: NewPlaylistCellViewModel(
//                        playlist: model(),
//                        displayType: .toggle
//                    ),
//                    isSelected: .constant(true)
//                )
//                .frame(width: 350, height: 81)
//                .background(.white)
//                .listRowSeparator(.hidden)
//
//                NewPlaylistCellView(
//                    viewModel: NewPlaylistCellViewModel(
//                        playlist: model(),
//                        displayType: .check
//                    ),
//                    isSelected: .constant(true)
//                )
//                .frame(width: 350, height: 81)
//                .background(.white)
//                .listRowSeparator(.hidden)
//
//                NewPlaylistCellView(
//                    viewModel: NewPlaylistCellViewModel(
//                        playlist: model(),
//                        displayType: .check
//                    ),
//                    isSelected: .constant(false)
//                )
//                .frame(width: 350, height: 81)
//                .background(.white)
//                .listRowSeparator(.hidden)
//            }
//        }
//
//        private func model() -> EpisodeFilter {
//            let filter = EpisodeFilter()
//            filter.playlistName = "New Releases"
//            return filter
//        }
//    }
//    return PreviewWrapper()
//        .environmentObject(Theme.sharedTheme)
//}
