import SwiftUI
import PocketCastsDataModel

struct PlaylistDetailView: View {

    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel
    @Environment(\.dismiss) var dismiss

    let model: PlaylistDetailsViewModel
    @FocusState private var focusedSection: FocusSection?
    @FocusState private var rowFocus: EpisodeRowFocus?

    enum FocusSection: Hashable {
        case episodes
    }

    enum Layout {
        static let mosaicSize = CGFloat(418)
        static let mosaicTileSize = CGFloat(209)
        static let infoPanelWidth = CGFloat(568)
        static let gutter = CGFloat(24)
        static let rowInsets = EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16)
    }

    var body: some View {
        @Bindable var model = model
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                playlistView
            case .empty:
                emptyView
            }
        }
        .animation(.smooth, value: model.state)
        .toolbar(.hidden, for: .tabBar)
        .defaultFocus($focusedSection, .episodes)
        .confirmationDialog(
            L10n.tvPlaylistPlayAllClearUpNextTitle,
            isPresented: $model.isShowingReplaceUpNextConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.tvPlaylistPlayAllPlayWithoutSaving, role: .confirm) {
                model.playWithoutSaving()
            }
            Button(L10n.tvPlaylistPlayAllSaveAndPlay) {
                model.saveUpNextAndPlay()
            }
            Button(L10n.cancel, role: .cancel) {
                model.replaceUpNextConfirmationDismissed()
            }
        } message: {
            Text(L10n.tvPlaylistPlayAllClearUpNextMessage)
        }
        .fullScreenCover(isPresented: $model.isShowingNowPlaying) {
            NowPlayingView()
                .ignoresSafeArea()
        }
        .task {
            Analytics.track(.filterShown, properties: ["filter_type": model.isManual ? "manual" : "smart"])
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var allArchivedEmptyView: some View {
        ContentUnavailableView {
            Label(L10n.tvPlaylistEmptyTitle, systemImage: "info.circle")
        } description: {
            VStack {
                HStack {
                    Spacer()
                    Text(L10n.tvPlaylistManualArchivedEpisodesPlaceholder(model.allEpisodesCount))
                    Spacer()
                }
            }.padding(24)
        } actions: {
            VStack {
                Button(L10n.tvPodcastDetailShowArchived) {
                    model.setShowArchived(true)
                }
                Spacer()
            }
        }
    }

    var emptyView: some View {
        ContentUnavailableView {
            Label(L10n.tvPlaylistEmptyTitle, systemImage: "info.circle")
        } description: {
            VStack {
                model.hasDownloadFilter ? Text(L10n.tvPlaylistDownloadRulesUnsupported) : Text(L10n.tvPlaylistEmptySubtitle)
            }.padding(24)
        } actions: {
            Button(L10n.ok) {
                dismiss()
            }
        }
    }

    var playlistView: some View {
        HStack(alignment: .top, spacing: Layout.gutter) {
            playlistInfo
                .frame(width: Layout.infoPanelWidth)
            if model.areAllEpisodesArchived {
                allArchivedEmptyView
            } else {
                episodeList
            }
        }
        .blurredCoverBackground(size: Layout.mosaicSize) {
            blurredMosaic
        }
    }

    @ViewBuilder
    private var blurredMosaic: some View {
        let images = model.coverPodcastsUuids
        if images.count >= 4 {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    PodcastImage(uuid: images[0], size: .page)
                    PodcastImage(uuid: images[1], size: .page)
                }
                HStack(spacing: 0) {
                    PodcastImage(uuid: images[2], size: .page)
                    PodcastImage(uuid: images[3], size: .page)
                }
            }
        } else if let first = images.first {
            PodcastImage(uuid: first, size: .page).aspectRatio(contentMode: .fill)
        }
    }

    @ViewBuilder
    var mosaicCover: some View {
        let images = model.coverPodcastsUuids
        switch images.count {
        case 0:
            ZStack {
                Image(ImageResource.pcLogo)
                    .resizable()
                    .accessibilityHidden(true)
                    .frame(width: Layout.mosaicSize * 0.75, height: Layout.mosaicSize * 0.75)
            }
            .frame(width: Layout.mosaicSize, height: Layout.mosaicSize)
            .background(Color.pcBackgroundSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        case 1...3:
            PodcastImage(uuid: images[0], size: .page)
                .frame(width: Layout.mosaicSize, height: Layout.mosaicSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        default:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    PodcastImage(uuid: images[0], size: .page)
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                    PodcastImage(uuid: images[1], size: .page)
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                }
                HStack(spacing: 0) {
                    PodcastImage(uuid: images[2], size: .page)
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                    PodcastImage(uuid: images[3], size: .page)
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                }
            }
            .frame(width: Layout.mosaicSize, height: Layout.mosaicSize)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    var playlistInfo: some View {
        VStack(alignment: .leading, spacing: 40) {
            mosaicCover
                .shadow(color: .pcShadowStrong, radius: 40, x: 0, y: 20)
            VStack(alignment: .leading, spacing: 8) {
                if !model.isManual {
                    Text(L10n.smartPlaylist)
                        .font(.caption)
                        .foregroundColor(.pcTextSecondary)
                }
                Text(model.playlistName)
                    .font(.title2)
                    .foregroundColor(.pcTextPrimary)
                Text("\(model.episodeCountText) · \(model.totalDuration)")
                    .font(.caption)
                    .foregroundColor(.pcTextSecondary)
            }
            .accessibilityElement(children: .combine)
            if !model.episodes.isEmpty {
                Button {
                    model.playAll()
                } label: {
                    Text(L10n.tvPlaylistDetailPlayAll)
                        .font(.caption2)
                }
            }
        }
        .focusSection()
    }

    @Namespace private var episodeListNamespace

    @State private var lastFocus: String?
    @FocusState private var currentFocus: String?

    var episodeList: some View {
        List {
            Section {
                ForEach(model.episodes, id: \.uuid) { episode in
                    EpisodeRowWithActions(model: EpisodeRowViewModel(episode: episode, podcast: nil, source: .filters), context: .other(showGoToPodcast: true), focus: $rowFocus, detailsDismissed: {
                        currentFocus = lastFocus
                    })
                    .focused($currentFocus, equals: episode.uuid)
                    .prefersDefaultFocus(episode.uuid == model.episodes.first?.uuid, in: episodeListNamespace)
                    .listRowInsets(Layout.rowInsets)
                }
            } header: {
                if model.isManual {
                    HStack {
                        Spacer()
                        archivedFilterMenu
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .onChange(of: rowFocus) { _, new in
            if let new {
                lastFocus = new.episodeID
            }
        }
        .onAppear {
            currentFocus = lastFocus
        }
        .focusScope(episodeListNamespace)
        .padding(.horizontal, 24)
        .contentMargins(.bottom, 24, for: .scrollContent)
        .focused($focusedSection, equals: .episodes)
    }

    private var archivedFilterMenu: some View {
        Menu {
            Button {
                model.setShowArchived(false)
            } label: {
                if model.showArchived {
                    Text(L10n.tvPodcastDetailHideArchived)
                } else {
                    Label(L10n.tvPodcastDetailHideArchived, systemImage: "checkmark")
                }
            }
            Button {
                model.setShowArchived(true)
            } label: {
                if model.showArchived {
                    Label(L10n.tvPodcastDetailShowArchived, systemImage: "checkmark")
                } else {
                    Text(L10n.tvPodcastDetailShowArchived)
                }
            }
        } label: {
            ArchivedFilterLabel(showArchived: model.showArchived)
        }
        .accessibilityLabel(L10n.tvPodcastDetailArchivedFilter)
    }

    private struct ArchivedFilterLabel: View {
        let showArchived: Bool

        var body: some View {
            HStack(spacing: 8) {
                Text(showArchived ? L10n.tvPodcastDetailShowArchived : L10n.tvPodcastDetailHideArchived)
                Image(systemName: "chevron.down")
            }
            .font(.caption2)
            .foregroundStyle(Color.pcTextPrimary)
        }
    }
}

#Preview {
    let router = MainTabViewModel()
    PlaylistDetailView(model: PlaylistDetailsViewModel(playlist: PlaylistItem(playlist: MockData.makeStubPlaylists().first!)))
        .environment(AppCoordinator())
        .environment(router)
}
