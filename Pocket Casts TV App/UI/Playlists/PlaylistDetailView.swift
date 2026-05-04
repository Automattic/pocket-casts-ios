import SwiftUI
import Combine
import PocketCastsUtils

@Observable
class PlaylistDetailViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    let playlist: MockPlaylist

    init(playlist: MockPlaylist) {
        self.playlist = playlist
    }

    func load() {
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                state = .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }

    func playAll() {

    }

    var totalDuration: String {
        let total = playlist.episodes.reduce(0) { $0 + $1.duration }
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: total)
    }

    var episodeCountText: String {
        return L10n.tvPlaylistDetailEpisodeCount(playlist.episodes.count)
    }

    var coverImages: [String] {
        var seen = Set<String>()
        var unique = [String]()
        for episode in playlist.episodes {
            if seen.insert(episode.image).inserted {
                unique.append(episode.image)
            }
            if unique.count == 4 { break }
        }
        return unique
    }
}

struct PlaylistDetailView: View {

    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter
    let model: PlaylistDetailViewModel
    @FocusState private var focusedSection: FocusSection?

    enum FocusSection: Hashable {
        case episodes
    }

    enum Layout {
        static let mosaicSize = CGFloat(418)
        static let mosaicTileSize = CGFloat(209)
        static let infoPanelWidth = CGFloat(568)
        static let gutter = CGFloat(24)
    }

    var body: some View {
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
    }

    @ViewBuilder
    var mosaicCover: some View {
        let images = model.coverImages
        switch images.count {
        case 0:
            Image(ImageResource.pcLogo)
                .resizable()
                .frame(width: Layout.mosaicSize, height: Layout.mosaicSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        case 1...3:
            Image(images[0])
                .resizable()
                .frame(width: Layout.mosaicSize, height: Layout.mosaicSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        default:
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(images[0])
                        .resizable()
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                    Image(images[1])
                        .resizable()
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                }
                HStack(spacing: 0) {
                    Image(images[2])
                        .resizable()
                        .frame(width: Layout.mosaicTileSize, height: Layout.mosaicTileSize)
                    Image(images[3])
                        .resizable()
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
            VStack(alignment: .leading, spacing: 8) {
                Text(model.playlist.manual ? "" : L10n.smartPlaylist)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(model.playlist.title)
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                Text("\(model.episodeCountText) · \(model.totalDuration)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            if !model.playlist.episodes.isEmpty {
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
        ScrollView {
            LazyVStack {
                ForEach(model.playlist.episodes) { episode in
                    EpisodePlayerButton(
                        episode: episode,
                        podcastTitle: model.playlist.title
                    )
                    .prefersDefaultFocus(episode.id == model.playlist.episodes.first?.id, in: episodeListNamespace)
                }
            }
            .focusScope(episodeListNamespace)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .focused($focusedSection, equals: .episodes)
    }
}

#Preview {
    let router = MainTabRouter()
    PlaylistDetailView(model: PlaylistDetailViewModel(playlist: MockData.makePlaylists().first!))
        .environment(AppCoordinator())
        .environment(router)
}
