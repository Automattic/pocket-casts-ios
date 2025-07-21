import SwiftUI
import PocketCastsDataModel

class PlaylistCellViewModel: ObservableObject {
    @Published var episodesCount: Int = 0
    @Published var imageURLs: [URL] = []

    private var playlist: EpisodeFilter?
    private var isLoadingCount: Bool = false
    private var isLoadingImages: Bool = false

    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let episodesDataManager: EpisodesDataManager
    private let episodeArtWork: EpisodeArtwork

    init(
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init()
    ) {
        self.dataManager = dataManager
        self.imageManager = imageManager
        self.episodeArtWork = .init(imageManager: imageManager)
        self.episodesDataManager = episodesDataManager
    }

    func playListName() -> String {
        playlist?.playlistName ?? ""
    }

    func isSmartPlaylist() -> Bool {
        playlist?.playlistType == .smart
    }

    func set(playlist: EpisodeFilter) {
        imageURLs.removeAll()

        self.playlist = playlist

        loadCount()
        loadImages()
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
        if isLoadingImages { return }
        isLoadingImages = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let list = await self.loadListEpisodes()
                let imageURLs = try await self.loadImagesURLs(episodes: list)
                await MainActor.run {
                    self.imageURLs = imageURLs
                    self.isLoadingImages = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImages = false
                }
            }
        }
    }

    private func loadListEpisodes() async -> [ListEpisode] {
        guard let playlist = self.playlist else {
            return []
        }
        return await Task.detached(priority: .userInitiated) { [weak self] in
            self?.episodesDataManager.episodes(for: playlist, limit: 4) ?? []
        }.value
    }

    private func loadImagesURLs(episodes: [ListEpisode]) async throws -> [URL] {
        try await withThrowingTaskGroup(of: URL.self) { group in
            for episode in episodes {
                group.addTask {
                    if let imageUrl = try await ShowInfoCoordinator.shared.loadEpisodeArtworkUrl(podcastUuid: episode.episode.podcastUuid, episodeUuid: episode.episode.uuid),
                       let url = URL(string: imageUrl) {
                        return url
                    }
                    return self.imageManager.podcastUrl(imageSize: .grid, uuid: episode.episode.podcastUuid)
                }
            }
            var results: [URL] = []
            for try await url in group {
                results.append(url)
            }
            return results
        }
    }

    private func getEpisodesCount() async -> Int {
        guard let playlist = self.playlist else {
            return 0
        }
        return await Task.detached(priority: .userInitiated) {
            DataManager.sharedManager.episodeCount(
                forFilter: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
            )
        }.value
    }
}
