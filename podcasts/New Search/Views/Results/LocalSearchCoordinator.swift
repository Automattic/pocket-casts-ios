import Foundation
import Combine
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

@MainActor
final class LocalSearchCoordinator {
    @Published private(set) var episodes: [EpisodeSearchResult] = []
    @Published private(set) var isSearchInFlight = false
    @Published private(set) var addedEpisodeCount = 0

    private let playlist: EpisodeFilter
    private let dataManager: DataManager

    private var playlistEpisodeUUIDs = Set<String>()
    private var preloadTask: Task<Void, Never>?

    init(
        playlist: EpisodeFilter,
        dataManager: DataManager = DataManager.sharedManager
    ) {
        self.playlist = playlist
        self.dataManager = dataManager
    }

    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.cancelPreloadTask()
        }
    }

    func refreshPlaylistEpisodes() {
        let playlistEpisodes = dataManager.playlistEpisodes(for: playlist)
        playlistEpisodeUUIDs = Set(playlistEpisodes.map { $0.uuid })
    }

    func clearResults() {
        cancelPreloadTask()
        isSearchInFlight = false
        episodes = []
    }

    func preloadEpisodes(for podcast: Podcast?) {
        cancelPreloadTask()
        episodes = []
        guard let podcast else {
            isSearchInFlight = false
            return
        }

        schedulePreloadTask(for: podcast)
    }

    private func schedulePreloadTask(for podcast: Podcast) {
        cancelPreloadTask()
        isSearchInFlight = true
        preloadTask = Task { [weak self] in
            guard let self else { return }

            let podcastEpisodes = dataManager.allEpisodesForPodcast(id: podcast.id)
            let sortedEpisodes = podcastEpisodes.sorted { lhs, rhs in
                let lhsDate = lhs.publishedDate ?? lhs.addedDate ?? .distantPast
                let rhsDate = rhs.publishedDate ?? rhs.addedDate ?? .distantPast
                return lhsDate > rhsDate
            }

            let availableEpisodes = sortedEpisodes.filter { !self.playlistEpisodeUUIDs.contains($0.uuid) }
            self.episodes = availableEpisodes.map { EpisodeSearchResult(episode: $0) }
            self.isSearchInFlight = false
        }
    }

    @MainActor
    private func cancelPreloadTask() {
        preloadTask?.cancel()
        preloadTask = nil
    }

    func handleAddEpisode(_ searchResult: EpisodeSearchResult) {
        guard let episode = dataManager.findEpisode(uuid: searchResult.uuid) else {
            assertionFailure("Episode should exist")
            return
        }

        dataManager.add(episodes: [episode], to: playlist)
        playlistEpisodeUUIDs.insert(searchResult.uuid)
        episodes.removeAll { $0.uuid == searchResult.uuid }
        addedEpisodeCount += 1
    }
}


extension EpisodeSearchResult {
    init(episode: Episode, dataManager: DataManager = DataManager.sharedManager) {
        let publishedDate = episode.publishedDate ?? episode.addedDate ?? Date()
        let duration = episode.duration > 0 ? episode.duration : nil
        let podcastTitle = episode.parentPodcast(dataManager: dataManager)?.title ?? ""

        self.init(uuid: episode.uuid, title: episode.displayableTitle(), publishedDate: publishedDate, duration: duration, podcastUuid: episode.podcastUuid, podcastTitle: podcastTitle)
    }
}
