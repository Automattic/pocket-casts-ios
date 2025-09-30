import SwiftUI
import PocketCastsDataModel

struct PlaylistCellView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistCellViewModel

    @Binding private var isSelected: Bool
    private var onTap: (() -> Void)? = nil

    private var title: String {
        switch viewModel.displayType {
        case .addNew:
            return L10n.playlistsDefaultNewPlaylist
        default:
            return viewModel.playListName()
        }
    }

    private var subtitle: String? {
        switch viewModel.displayType {
        case .check:
            return "\(viewModel.episodesCount) episodes"
        case .toggle, .count:
            if viewModel.isSmartPlaylist() {
                return L10n.smartPlaylist
            }
            return nil
        default:
            return nil
        }
    }
    
    init(
        viewModel: PlaylistCellViewModel,
        isSelected: Binding<Bool> = .constant(false),
        onTap: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self._isSelected = isSelected
        self.onTap = onTap
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
                PlaylistArtworkView(items: viewModel.images, imageSize: 168)
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
        .if(viewModel.displayType == .check) { view in
            view
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.isBelowEpisodeLimit {
                        isSelected.toggle()
                    }
                    onTap?()
                }
        }
        .onAppear {
            viewModel.loadData()
        }
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
        case .toggle:
            Toggle("", isOn: $isSelected)
                .labelsHidden()
                .tint(theme.primaryInteractive01)
                .padding(.trailing, 16.0)
        case .check:
            ZStack {
                let image = isSelected ? "checkbox-selected" : "checkbox-unselected"
                let color = isSelected ? theme.primaryInteractive01 : theme.primaryIcon03
                Image(image)
                    .renderingMode(.template)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Image("tick")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryInteractive02)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.trailing, 16.0)
        case .addNew:
            EmptyView()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @EnvironmentObject var theme: Theme

        var body: some View {
            List {
                PlaylistCellView(
                    viewModel: PlaylistCellViewModel(
                        playlist: model(),
                        displayType: .addNew
                    ),
                    isSelected: .constant(true)
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)

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

                PlaylistCellView(
                    viewModel: PlaylistCellViewModel(
                        playlist: model(),
                        displayType: .check
                    ),
                    isSelected: .constant(true)
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)

                PlaylistCellView(
                    viewModel: PlaylistCellViewModel(
                        playlist: model(),
                        displayType: .check
                    ),
                    isSelected: .constant(false)
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
