import SwiftUI
import PocketCastsDataModel

struct PlaylistDetailView: View {

    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter
    let model: PlaylistDetailsViewModel
    @FocusState private var focusedSection: FocusSection?

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
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .defaultFocus($focusedSection, .episodes)
        .onAppear { tabRouter.isShowingDetail = true }
        .onDisappear { tabRouter.isShowingDetail = false }
        .confirmationDialog(
            L10n.playlistPlayAllSheetTitle,
            isPresented: $model.isShowingReplaceUpNextConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.playlistPlayAllSheetButtonTitle, role: .confirm) {
                model.buttonConfirmPlayPlaylistTapped()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.playlistPlayAllSheetDescription)
        }
        .fullScreenCover(isPresented: $model.isShowingNowPlaying) {
            NowPlayingView()
                .ignoresSafeArea()
        }
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var playlistView: some View {
        HStack(alignment: .top, spacing: Layout.gutter) {
            playlistInfo
                .frame(width: Layout.infoPanelWidth)
            episodeList
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
            Image(ImageResource.pcLogo)
                .resizable()
                .frame(width: Layout.mosaicSize, height: Layout.mosaicSize)
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

    var episodeList: some View {
        List {
            ForEach(model.episodes, id: \.uuid) { episode in
                EpisodeRowWithActions(model: EpisodeRowViewModel(episode: episode, podcast: nil))
                    .prefersDefaultFocus(episode.uuid == model.episodes.first?.uuid, in: episodeListNamespace)
                    .listRowInsets(Layout.rowInsets)
            }
        }
        .focusScope(episodeListNamespace)
        .padding(.horizontal, 24)
        .contentMargins(.bottom, 24, for: .scrollContent)
        .focused($focusedSection, equals: .episodes)
    }
}

#Preview {
    let router = MainTabRouter()
    PlaylistDetailView(model: PlaylistDetailsViewModel(playlist: MockData.makeStubPlaylists().first!))
        .environment(AppCoordinator())
        .environment(router)
}
