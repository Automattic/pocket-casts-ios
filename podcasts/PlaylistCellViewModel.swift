import SwiftUI
import PocketCastsDataModel

#if canImport(UIKit)
import UIKit
#endif

class PlaylistCellViewModel: ObservableObject {
    enum DisplayType {
        case count
        case toggle
        case check
        case addNew
        case plain
    }

    @Published var episodesCount: Int = 0
    @Published var images: [PlaylistArtworkView.ImageItem] = []

    var isBelowEpisodeLimit: Bool {
#if DEBUG
        episodesCount < Settings.debugPlaylistsLimit
#else
        episodesCount < Constants.Limits.maxFilterItems
#endif
    }

    static func distinctPodcasts<T>(
        from episodes: [T],
        limit: Int,
        podcastUuid: (T) -> String
    ) -> [T] {
        var seen = Set<String>()
        var results: [T] = []

        for episode in episodes {
            if seen.insert(podcastUuid(episode)).inserted {
                results.append(episode)

                if results.count == limit {
                    break
                }
            }
        }

        return results
    }

    static func gridArtworkItems<T>(
        from episodes: [T],
        limit: Int,
        imageManager: ImageManager = .sharedManager,
        podcastUuid: (T) -> String
    ) -> [PlaylistArtworkView.ImageItem] {
        let distinctEpisodes = distinctPodcasts(from: episodes, limit: limit, podcastUuid: podcastUuid)

        return distinctEpisodes.map { episode in
            let uuid = podcastUuid(episode)
            let url = imageManager.podcastUrl(imageSize: .grid, uuid: uuid)
            return PlaylistArtworkView.ImageItem(id: uuid, url: url)
        }
    }

    private var playlist: EpisodeFilter
    private var isLoadingCount: Bool = false
    private var isLoadingImages: Bool = false

    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let episodesDataManager: EpisodesDataManager
    private let episodeArtWork: EpisodeArtwork

    let displayType: DisplayType

    init(
        playlist: EpisodeFilter,
        displayType: DisplayType = .count,
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init()
    ) {
        self.playlist = playlist
        self.displayType = displayType
        self.dataManager = dataManager
        self.imageManager = imageManager
        self.episodeArtWork = .init(imageManager: imageManager)
        self.episodesDataManager = episodesDataManager
    }

    func playListName() -> String {
        playlist.playlistName
    }

    func isSmartPlaylist() -> Bool {
        playlist.manual == false
    }

    func loadData() {
        images.removeAll()

        switch displayType {
        case .count, .check:
            loadCount()
            loadImages()
        case .toggle, .plain:
            loadImages()
        case .addNew:
            return
        }
    }

    private func loadCount() {
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

    private func loadImages() {
        if isLoadingImages { return }
        isLoadingImages = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let list = await self.loadListEpisodes()
                let firstFourDistinct = self.firstDistinctPodcasts(from: list, limit: 4)
                let images = try await self.loadImagesURLs(episodes: firstFourDistinct)
                await MainActor.run {
                    self.images = images
                    self.isLoadingImages = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingImages = false
                }
            }
        }
    }

    private func loadListEpisodes(limit: Int = Constants.Limits.maxFilterItems) async -> [ListEpisode] {
        let playlist = self.playlist
        return await Task.detached(priority: .userInitiated) { [weak self] in
            self?.episodesDataManager.playlistEpisodes(for: playlist, limit: limit, shouldShowArchived: playlist.showArchivedEpisodes) ?? []
        }.value
    }

    private func loadImagesURLs(episodes: [ListEpisode], includingEpisodeArtwork: Bool = false) async throws -> [PlaylistArtworkView.ImageItem] {
        try await withThrowingTaskGroup(of: PlaylistArtworkView.ImageItem.self) { group in
            for episode in episodes {
                group.addTask {
                    if includingEpisodeArtwork,
                       let imageUrl = try await ShowInfoCoordinator.shared.loadEpisodeArtworkUrl(podcastUuid: episode.episode.podcastUuid, episodeUuid: episode.episode.uuid),
                       let url = URL(string: imageUrl) {
                        return PlaylistArtworkView.ImageItem(id: episode.episode.uuid, url: url)
                    }
                    let url = self.imageManager.podcastUrl(imageSize: .grid, uuid: episode.episode.podcastUuid)
                    return PlaylistArtworkView.ImageItem(id: episode.episode.podcastUuid, url: url)
                }
            }
            var results: [PlaylistArtworkView.ImageItem] = []
            for try await item in group {
                results.append(item)
            }

            let mapEpisodes = Dictionary(uniqueKeysWithValues: episodes.enumerated().map { ($1.episode.uuid, $0) })
            let mapPodcasts = Dictionary(uniqueKeysWithValues: episodes.enumerated().map { ($1.episode.podcastUuid, $0) })

            return results.sorted { lhs, rhs in
                let lhsIndex = (mapEpisodes[lhs.id] ?? mapPodcasts[lhs.id]) ?? Int.max
                let rhsIndex = (mapEpisodes[rhs.id] ?? mapPodcasts[rhs.id]) ?? Int.max
                return lhsIndex < rhsIndex
            }
        }
    }

    private func getEpisodesCount() async -> Int {
        let playlist = self.playlist
        let dataManager = self.dataManager

        return await Task.detached(priority: .userInitiated) {
            dataManager.allPlaylistEpisodeCount(
                for: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
            )
        }.value
    }

    private func firstDistinctPodcasts(from episodes: [ListEpisode], limit: Int) -> [ListEpisode] {
        Self.distinctPodcasts(from: episodes, limit: limit) { $0.episode.podcastUuid }
    }
}
