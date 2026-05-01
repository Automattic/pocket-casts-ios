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
        while unique.count < 4, let first = unique.first {
            unique.append(first)
        }
        return unique
    }
}

struct PlaylistDetailView: View {

    let model: PlaylistDetailViewModel

    enum Layout {
        static let mosaicSize = CGFloat(418)
        static let mosaicTileSize = CGFloat(209)
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
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var playlistView: some View {
        HStack(alignment: .top) {
            playlistInfo
            VStack {
                episodeList
            }
            Spacer()
        }
        .toolbar(.hidden, for: .tabBar)
    }

    var mosaicCover: some View {
        let images = model.coverImages
        return VStack(spacing: 0) {
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
            Button {
                model.playAll()
            } label: {
                Text(L10n.tvPlaylistDetailPlayAll)
                    .font(.caption2)
            }
        }
        .focusSection()
    }

    var episodeList: some View {
        ScrollView {
            LazyVStack {
                ForEach(model.playlist.episodes) { episode in
                    NavigationLink(value: episode) {
                        EpisodeRow(episode: episode)
                    }
                    .buttonStyle(EpisodeRowButtonStyle())
                }
            }
            .navigationDestination(for: MockEpisode.self) { episode in
                VStack {
                    Button {

                    } label: {
                        Text("Episode \(episode.title) details coming soon")
                            .font(.title2)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    PlaylistDetailView(model: PlaylistDetailViewModel(playlist: MockData.makePlaylists().first!))
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
