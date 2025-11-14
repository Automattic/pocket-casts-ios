import SwiftUI
import PocketCastsDataModel

struct NewPlaylistCellView: View {
    enum DisplayType {
        case count
        case toggle
        case check
        case addNew
        case plain
    }

    @EnvironmentObject var theme: Theme

    @Binding private var isSelected: Bool

    @State private var refreshToken = UUID()
    @State private var episodesCount: Int = 0
    @State private var playlistName: String = ""
    @State private var isSmartPlaylist: Bool = false

    private let canBeDisabled: Bool
    private let analyticsSource: String?
    private let displayType: DisplayType

    private var title: String {
        switch displayType {
        case .addNew:
            return L10n.playlistsDefaultNewPlaylist
        default:
            return playlistName
        }
    }

    private var subtitle: String? {
        switch displayType {
        case .check:
            return L10n.playlistEpisodesCount(episodesCount)
        case .toggle, .count, .plain:
            if isSmartPlaylist {
                return L10n.smartPlaylist
            }
            return nil
        default:
            return nil
        }
    }

    private var isBelowEpisodeLimit: Bool {
#if DEBUG
        episodesCount < Settings.debugPlaylistsLimit
#else
        episodesCount < Constants.Limits.maxFilterItems
#endif
    }

    var shouldDisableRow: Bool {
        canBeDisabled &&
        !isSelected &&
        !isBelowEpisodeLimit
    }

    init(
        displayType: DisplayType,
        isSelected: Binding<Bool> = .constant(false),
        canBeDisabled: Bool = false,
        analyticsSource: String? = nil
    ) {
        self.displayType = displayType
        self._isSelected = isSelected
        self.canBeDisabled = canBeDisabled
        self.analyticsSource = analyticsSource
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
        .if(viewModel.displayType == .check) { view in
            view
                .contentShape(Rectangle())
                .onTapGesture {
                    trackTapEvent()

                    if !shouldDisableRow {
                        isSelected.toggle()
                        refreshToken = UUID()
                    } else {
                        let theme: any ToastTheme = ToastIconTheme(iconName: "option-alert", iconColor: Theme.sharedTheme.primaryIcon01)
                        Toast.show(L10n.playlistManualAddEpisodeFullPlaylistToast, theme: theme)
                    }
                }
        }
        .opacity(shouldDisableRow ? 0.45 : 1.0)
        
    }

    private func subtitleView(text: String) -> some View {
        Text(text)
            .foregroundStyle(theme.primaryText02)
            .font(size: 14.0, style: .body, weight: .regular)
    }

    @ViewBuilder private func accesoryView() -> some View {
        switch displayType {
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
            .id(refreshToken)
        case .addNew, .plain:
            EmptyView()
        }
    }

    private func trackTapEvent() {
        let event: AnalyticsEvent = !isSelected ? .addToPlaylistsEpisodeAddTapped : .addToPlaylistsRemoveTapped
        var properties = ["source": self.analyticsSource ?? "unknown"]
        if !isSelected {
            properties["is_playlist_full"] = shouldDisableRow ? "true" : "false"
        }
        Analytics.track(event, properties: properties)
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
                        displayType: .plain
                    ),
                    isSelected: .constant(true)
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)

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
