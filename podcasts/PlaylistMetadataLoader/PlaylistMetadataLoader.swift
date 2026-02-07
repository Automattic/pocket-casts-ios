import PocketCastsDataModel
import PocketCastsUtils

actor PlaylistMetadataLoader {

    private struct Cache {
        var counts: [String: Int] = [:] {
            didSet {
                lastUpdate = Date()
            }
        }

        var images: [String: [PlaylistArtworkView.ImageItem]] = [:] {
            didSet {
                lastUpdate = Date()
            }
        }
        var lastUpdate: Date?

        mutating func clear() {
            counts.removeAll()
            images.removeAll()
            lastUpdate = nil
        }
    }

    private var cache = Cache()

    private var countTasks: [String: Task<Int, Never>] = [:]
    private var imagesTasks: [String: Task<[PlaylistArtworkView.ImageItem], Never>] = [:]

    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let episodesDataManager: EpisodesDataManager

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

    init(
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init()
    ) {
        self.dataManager = dataManager
        self.imageManager = imageManager
        self.episodesDataManager = episodesDataManager
    }

    func cachedCount(for playlistID: String) -> Int? {
        return cache.counts[playlistID]
    }

    func cachedImages(for playlistID: String) -> [PlaylistArtworkView.ImageItem]? {
        return cache.images[playlistID]
    }

    func loadCount(for playlist: EpisodeFilter) async -> Int {
        let playlistID = playlist.uuid

        // Avoid duplicate fetches
        if let task = countTasks[playlistID] {
            return await task.value
        }

        // Start new fetch task
        let task = Task {
            let newCount = await getEpisodesCount(for: playlist)

            countTasks[playlistID] = nil

            if let cached = cache.counts[playlistID], cached == newCount {
                return cached
            }

            cache.counts[playlistID] = newCount
            return newCount
        }
        countTasks[playlistID] = task
        return await task.value
    }

    func loadImages(for playlist: EpisodeFilter) async -> [PlaylistArtworkView.ImageItem] {
        let playlistID = playlist.uuid

        // Avoid duplicate fetches
        if let task = imagesTasks[playlistID] {
            return await task.value
        }

        // Start new fetch task
        let task = Task {
            defer {
                imagesTasks[playlistID] = nil
            }
            let episodes = await loadListEpisodes(for: playlist)
            let distinctEpisodes = firstDistinctPodcasts(from: episodes)

            do {
                let items = try await loadImagesURLs(episodes: distinctEpisodes)

                if let cached = cache.images[playlistID], cached == items {
                    return cached
                }

                cache.images[playlistID] = items

                return items
            } catch {
                return cache.images[playlistID] ?? []
            }

        }
        imagesTasks[playlistID] = task
        return await task.value
    }

    func cancelLoadCount(for playlistID: String) {
        countTasks[playlistID]?.cancel()
        countTasks[playlistID] = nil
    }

    func cancelLoadImages(for playlistID: String) {
        imagesTasks[playlistID]?.cancel()
        imagesTasks[playlistID] = nil
    }

    /// Invalidates the cache if it's older than the specified threshold.
    /// Call this when the view appears to ensure fresh data after the threshold.
    /// - Parameter threshold: Time interval after which cache is considered stale. Defaults to 30 seconds.
    /// - Returns: Whether the cache was invalidated.
    @discardableResult
    func invalidateCacheIfStale(threshold: TimeInterval = 30) -> Bool {
        guard let lastUpdate = cache.lastUpdate else {
            // No cache yet, nothing to invalidate
            return false
        }

        let elapsed = Date().timeIntervalSince(lastUpdate)
        if elapsed > threshold {
            cache.clear()
            return true
        }
        return false
    }

    private func getEpisodesCount(for playlist: EpisodeFilter) async -> Int {
        let playlist = playlist
        let dataManager = self.dataManager

        return await Task(priority: FeatureFlag.playlistDataCacheBeforeQuery.enabled ? .medium : .userInitiated) {
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
        return await Task(priority: FeatureFlag.playlistDataCacheBeforeQuery.enabled ? .medium : .userInitiated) {
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
