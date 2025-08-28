import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import DifferenceKit

class PlaylistDetailViewModel: ObservableObject {
    enum ButtonTag {
        case smartRules
        case addEpisodes
        case playAll
    }

    private(set) var playlist: EpisodeFilter!

    let onButtonTapped: (ButtonTag) -> Void

    private var tempEpisodes: [ListEpisode] = []
    @Published private(set) var episodes: [ListEpisode] = []
    @Published var images: [PlaylistArtworkView.ImageItem] = []
    @Published var episodesCount: Int = 0

    private(set) var isSearching = false
    private(set) var firstTimeLoading = true

    private var searchTerm: String = ""
    private var isLoadingData: Bool = false
    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let episodesDataManager: EpisodesDataManager
    private let onChange: (StagedChangeset<[ListEpisode]>, Bool, Bool) -> Void
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(
        playlist: EpisodeFilter,
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init(),
        onChange: @escaping (StagedChangeset<[ListEpisode]>, Bool, Bool) -> Void,
        onButtonTapped: @escaping (ButtonTag) -> Void
    ) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.imageManager = imageManager
        self.episodesDataManager = episodesDataManager
        self.onChange = onChange
        self.onButtonTapped = onButtonTapped
    }

    func update(episodes: [ListEpisode]) {
        self.episodes = episodes

        if isLoadingData { return }
        isLoadingData = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let count = await self.getEpisodesCount()
                if self.isSearching {
                    await MainActor.run {
                        self.episodesCount = count
                        self.isLoadingData = false
                    }
                } else {
                    let firstFourDistinct = self.firstDistinctPodcasts(from: episodes, limit: 4)
                    let images = try await self.loadImagesURLs(episodes: firstFourDistinct)
                    await MainActor.run {
                        self.images = images
                        self.episodesCount = count
                        self.isLoadingData = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingData = false
                }
            }
        }
    }

    func update(playlist: EpisodeFilter) {
        self.playlist = playlist
    }

    func reloadPlaylistAndEpisodes() {
        if isSearching {
            searchEpisodes(for: searchTerm)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let reloadedPlaylist = DataManager.sharedManager.findFilter(uuid: playlist.uuid) {
                DispatchQueue.main.async { [weak self] in
                    self?.playlist = reloadedPlaylist
                }
            }
            reloadEpisodeList(animated: false)
        }
    }

    func reloadEpisodeList(animated: Bool = true) {
        if isSearching {
            searchEpisodes(for: searchTerm)
            return
        }
        operationQueue.cancelAllOperations()

        let refreshOperation = PlaylistRefreshOperation(filter: playlist) { [weak self] newData in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.firstTimeLoading {
                    self.firstTimeLoading.toggle()
                }
                let contentChanged = !self.episodes.isContentEqual(to: newData)
                let changedData = contentChanged ? newData : self.episodes
                let changeSet = StagedChangeset(source: self.episodes, target: changedData, section: 1)
                self.onChange(changeSet, animated, contentChanged)
            }
        }
        operationQueue.addOperation(refreshOperation)
    }

    func totalDuration() -> String {
        let totalDuration = episodes.map { $0.episode.duration - $0.episode.playedUpTo }.reduce(0, +)
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalDuration)
    }

    private func loadListEpisodes(limit: Int = 4) async -> [ListEpisode] {
        let playlist = self.playlist!
        return await Task.detached(priority: .userInitiated) { [weak self] in
            self?.episodesDataManager.episodes(for: playlist, limit: limit) ?? []
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
        let playlist = self.playlist!
        let dataManager = self.dataManager
        return await Task.detached(priority: .userInitiated) {
            dataManager.episodeCount(
                forFilter: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
            )
        }.value
    }

    private func firstDistinctPodcasts(from episodes: [ListEpisode], limit: Int) -> [ListEpisode] {
        var seen = Set<String>()
        var list: [ListEpisode] = []

        for episode in episodes {
            if seen.insert(episode.episode.podcastUuid).inserted {
                list.append(episode)
                if list.count == limit {
                    break
                }
            }
        }
        return list
    }
}

extension PlaylistDetailViewModel {
    func clearSearch() {
        searchTerm = ""
        episodes = tempEpisodes
    }

    func endSearch() {
        isSearching = false
        searchTerm = ""
        episodes = tempEpisodes
        tempEpisodes.removeAll()

        reloadPlaylistAndEpisodes()
    }

    func startSearch() {
        if isSearching {
            return
        }
        isSearching = true
        tempEpisodes = episodes
    }

    func searchEpisodes(for searchTerm: String) {
        if searchTerm.isEmpty {
            return
        }
        self.searchTerm = searchTerm
        let escapedSearch = searchTerm.escapeLike(escapeChar: "\\")
        let newData = episodesDataManager.smartPlaylistEpisodes(for: playlist, limit: 0, search: escapedSearch)
        let contentChanged = !episodes.isContentEqual(to: newData)
        let changedData = contentChanged ? newData : episodes
        let changeSet = StagedChangeset(source: episodes, target: changedData, section: 1)
        DispatchQueue.main.async { [weak self] in
            self?.onChange(changeSet, true, contentChanged)
        }
    }
}
