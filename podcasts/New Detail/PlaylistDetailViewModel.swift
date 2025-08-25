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

    @Published private(set) var episodes: [ListEpisode] = []
    @Published var images: [PlaylistArtworkView.ImageItem] = []
    @Published var episodesCount: Int = 0

    var isSearching = false

    private(set) var firstTimeLoading = true

    private var isLoadingData: Bool = false
    private let dataManager: DataManager
    private let imageManager: ImageManager
    private let onChange: (StagedChangeset<[ListEpisode]>, Bool) -> Void
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init(
        playlist: EpisodeFilter,
        dataManager: DataManager = .sharedManager,
        imageManager: ImageManager = .sharedManager,
        onChange: @escaping (StagedChangeset<[ListEpisode]>, Bool) -> Void,
        onButtonTapped: @escaping (ButtonTag) -> Void
    ) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.imageManager = imageManager
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
                let firstFourDistinct = self.firstDistinctPodcasts(from: episodes, limit: 4)
                let images = try await self.loadImagesURLs(episodes: firstFourDistinct)
                await MainActor.run {
                    self.images = images
                    self.episodesCount = count
                    self.isLoadingData = false
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
        let refreshOperation = PlaylistRefreshOperation(filter: playlist) { [weak self] newData in
            guard let self else { return }
            DispatchQueue.main.async {
                if self.firstTimeLoading {
                    self.firstTimeLoading.toggle()
                }
                let changeSet = StagedChangeset(source: self.episodes, target: newData, section: 1)
                if !changeSet.isEmpty {
                    self.onChange(changeSet, animated)
                }
            }
        }
        operationQueue.addOperation(refreshOperation)
    }

    func totalDuration() -> String {
        let totalDuration = episodes.map { $0.episode.duration - $0.episode.playedUpTo }.reduce(0, +)
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: totalDuration)
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
