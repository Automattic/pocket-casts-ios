import PocketCastsDataModel

actor PlaylistMetadataLoader {
    private var counts: [String: Int] = [:]
    private var images: [String: [PlaylistArtworkView.ImageItem]] = [:]

    private var countTasks: [String: Task<Void, Never>] = [:]
    private var imagesTasks: [String: Task<Void, Never>] = [:]

    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let episodesDataManager: EpisodesDataManager

    init(
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init()
    ) {
        self.dataManager = dataManager
        self.imageManager = imageManager
        self.episodesDataManager = episodesDataManager
    }

    func cachedCount(for playlistID: String) -> Int {
        return counts[playlistID] ?? 0
    }

    func cachedImages(for playlistID: String) -> [PlaylistArtworkView.ImageItem] {
        return images[playlistID] ?? []
    }

    func loadMetadata(
        for playlist: EpisodeFilter,
        update: @escaping (Int, [PlaylistArtworkView.ImageItem]) -> Void,
        items: @escaping (Int, [PlaylistArtworkView.ImageItem]) -> Void
    ) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadCount(for: playlist, update: update)
            }
            group.addTask {
                await self.loadImages(for: playlist, update: items)
            }
        }
    }

    func loadCount(for playlist: EpisodeFilter, update: @escaping (Int, [PlaylistArtworkView.ImageItem]) -> Void) async {
        // Return cached immediately (but don't skip re-fetch)
        let playlistID = playlist.uuid
        if let cached = counts[playlistID] {
            let images = images[playlistID] ?? []
            Task { @MainActor in update(cached, images) }
        }

        // Avoid duplicate fetches
        guard countTasks[playlistID] == nil else { return }

        // Start new fetch task
        countTasks[playlistID] = Task {
            let newCount = await getEpisodesCount(for: playlist)

            let shouldUpdate: Bool
            if let cached = counts[playlistID] {
                shouldUpdate = (cached != newCount)
            } else {
                shouldUpdate = true
            }

            if shouldUpdate {
                counts[playlistID] = newCount
                let images = images[playlistID] ?? []
                await MainActor.run {
                    update(newCount, images)
                }
            }

            countTasks[playlistID] = nil
        }
    }

    func loadImages(for playlist: EpisodeFilter, update: @escaping (Int, [PlaylistArtworkView.ImageItem]) -> Void) async {
        // Return cached immediately (but don't skip re-fetch)
        let playlistID = playlist.uuid
        if let cached = images[playlistID] {
            let count = counts[playlistID] ?? 0
            Task { @MainActor in update(count, cached) }
        }

        // Avoid duplicate fetches
        guard imagesTasks[playlistID] == nil else { return }

        // Start new fetch task
        imagesTasks[playlistID] = Task {
            let episodes = await loadListEpisodes(for: playlist)
            let distinctEpisodes = firstDistinctPodcasts(from: episodes)

            do {
                let items = try await loadImagesURLs(episodes: distinctEpisodes)

                let shouldUpdate: Bool
                if let cached = images[playlistID] {
                    shouldUpdate = (cached != items)
                } else {
                    shouldUpdate = true
                }

                if shouldUpdate {
                    images[playlistID] = items
                    let count = counts[playlistID] ?? 0
                    await MainActor.run {
                        update(count, items)
                    }
                }
            } catch {
                let items = images[playlistID] ?? []
                let count = counts[playlistID] ?? 0
                await MainActor.run {
                    update(count, items)
                }
            }

            imagesTasks[playlistID] = nil
        }
    }

    private func getEpisodesCount(for playlist: EpisodeFilter) async -> Int {
        let playlist = playlist
        let dataManager = self.dataManager

        return await Task.detached(priority: .userInitiated) {
            dataManager.allPlaylistEpisodeCount(
                for: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries(),
                includingArchivedEpisodes: playlist.manual
            )
        }.value
    }

    private func loadListEpisodes(for playlist: EpisodeFilter) async -> [ListEpisode] {
        let playlist = playlist
        let episodesDataManager = self.episodesDataManager
        return await Task.detached(priority: .userInitiated) {
            episodesDataManager.playlistFirstDistinctEpisodes(
                for: playlist,
                shouldShowArchived: playlist.showArchivedEpisodes
            )
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

    private func firstDistinctPodcasts(
        from episodes: [ListEpisode],
        limit: Int = 4
    ) -> [ListEpisode] {
        Self.distinctPodcasts(from: episodes, limit: limit) { $0.episode.podcastUuid }
    }

    private static func distinctPodcasts<T>(
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
        if !results.isEmpty, results.count < limit {
            return Array(results.prefix(1))
        }
        return results
    }
}
