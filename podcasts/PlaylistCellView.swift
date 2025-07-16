import SwiftUI
import PocketCastsDataModel

class PlaylistCellViewModel: ObservableObject {
    @Published var episodesCount: Int = 0
    @Published var images: [Image] = []

    private let playlist: EpisodeFilter
    private let dataManager: DataManager
    private let episodesDataManager: EpisodesDataManager
    private var isLoadingCount: Bool = false
    private let episodeArtWork = EpisodeArtwork()

    init(
        playlist: EpisodeFilter,
        dataManager: DataManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init()
    ) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.episodesDataManager = episodesDataManager
    }

    func playListName() -> String {
        playlist.playlistName
    }

    func isSmartPlaylist() -> Bool {
        playlist.playlistType == .smart
    }

    func loadCount() {
        if isLoadingCount { return }
        isLoadingCount = true
        Task { [weak self] in
            guard let self else { return }
            let count = await self.getEpisodesCount()
            await MainActor.run {
                self.episodesCount = count
                self.isLoadingCount = false
            }
        }
    }

    func loadImages() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let list = await self.loadListEpisodes()
                let images = try await self.loadImages(episodes: list)
                await MainActor.run {
                    self.images = images
                }
            } catch {}
        }
    }

    private func getEpisodesCount() async -> Int {
        let playlist = self.playlist
        return await Task.detached(priority: .userInitiated) {
            DataManager.sharedManager.episodeCount(
                forFilter: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
            )
        }.value
    }

    func loadListEpisodes() async -> [ListEpisode] {
        let playlist = self.playlist
        return await Task.detached(priority: .userInitiated) { [weak self] in
            self?.episodesDataManager.episodes(for: playlist, limit: 4) ?? []
        }.value
    }

    func loadImages(episodes: [ListEpisode]) async throws -> [Image] {
        try await withThrowingTaskGroup(of: UIImage?.self) { group in
            for episode in episodes {
                group.addTask {
                    let episodeImage = try await self.episodeArtWork.loadEpisodeArtworkFromUrl(podcastUuid: episode.episode.podcastUuid, episodeUuid: episode.episode.uuid, size: 168)
                    if let episodeImage {
                        return episodeImage
                    }
                    let url = ImageManager.sharedManager.podcastUrl(imageSize: .grid, uuid: episode.episode.podcastUuid)
                    guard let podcastImage = try await self.episodeArtWork.loadArtwork(from: url.absoluteString, uuid: episode.episode.podcastUuid, size: 168) else {
                        return nil
                    }
                    return podcastImage
                }
            }

            var results: [Image] = []
            for try await image in group {
                if let image {
                    results.append(Image(uiImage: image))
                }
            }
            return results
        }
    }
}

struct PlaylistArtworkView: View {
    @EnvironmentObject var theme: Theme
    let images: [Image]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Rectangle()
                    .foregroundColor(theme.primaryUi05)
                if images.isEmpty {
                    Image("playlists_tab")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryIcon03)
                        .frame(width: size.width, height: size.height)
                } else {
                    switch images.count {
                    case 4:
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                images[0]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                images[1]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                            HStack(spacing: 0) {
                                images[2]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                                images[3]
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width / 2, height: size.height / 2)
                                    .clipped()
                            }
                        }
                    default:
                        images[0]
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    }
                }
            }
            .cornerRadius(4)
            .clipped()
        }
    }
}

struct PlaylistCellView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: PlaylistCellViewModel

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Rectangle()
                    .foregroundColor(theme.primaryUi05)
                    .frame(height: 1)
                    .padding(.leading, 16.0)
            }
            HStack(spacing: 16.0) {
                PlaylistArtworkView(images: viewModel.images)
                    .frame(width: 56.0, height: 56.0)
                    .padding(.leading, 16.0)
                VStack(alignment: .leading) {
                    Text(viewModel.playListName())
                        .foregroundStyle(theme.primaryText01)
                        .font(size: 15.0, style: .body, weight: .regular)
                    if viewModel.isSmartPlaylist() {
                        Text("Smart Playlist")
                            .foregroundStyle(theme.secondaryText02)
                            .font(size: 14.0, style: .body, weight: .regular)
                    }
                }
                Spacer()
                HStack(spacing: 5.0) {
                    Text("\(viewModel.episodesCount)")
                        .foregroundStyle(theme.secondaryText02)
                        .font(size: 14.0, style: .body, weight: .regular)
                    Image("cs-chevron")
                        .renderingMode(.template)
                        .foregroundStyle(theme.primaryIcon02)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .background(.clear)
        .onAppear {
            viewModel.loadCount()
            viewModel.loadImages()
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
                        playlist: model()
                    )
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)

                PlaylistCellView(
                    viewModel: PlaylistCellViewModel(
                        playlist: model()
                    )
                )
                .frame(width: 350, height: 81)
                .background(.white)
                .listRowSeparator(.hidden)
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
