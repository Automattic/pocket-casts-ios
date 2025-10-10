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
    private let searchResultsModel: SearchResultsModel
    private let dataManager: DataManager

    private var playlistEpisodeUUIDs = Set<String>()
    private var currentEpisodeSearchTerm = ""
    private var currentSearchPodcastUUID: String?
    private var searchTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?

    init(
        playlist: EpisodeFilter,
        searchResultsModel: SearchResultsModel,
        dataManager: DataManager = DataManager.sharedManager
    ) {
        self.playlist = playlist
        self.searchResultsModel = searchResultsModel
        self.dataManager = dataManager
    }

    deinit {
        searchTask?.cancel()
    }

    func refreshPlaylistEpisodes() {
        let playlistEpisodes = dataManager.playlistEpisodes(for: playlist)
        playlistEpisodeUUIDs = Set(playlistEpisodes.map { $0.uuid })
    }

    func scheduleSearch(for trimmedTerm: String, podcastUuid: String?) {
        cancelPendingSearch()

        guard trimmedTerm.count >= 2, let podcastUuid else {
            clearPendingSearchState()
            return
        }

        scheduleSearchTask(delay: .milliseconds(3), term: trimmedTerm, podcastUuid: podcastUuid)
    }

    func triggerImmediateSearch(for trimmedTerm: String, podcastUuid: String?) {
        cancelPendingSearch()

        guard trimmedTerm.count >= 2, let podcastUuid else {
            clearPendingSearchState()
            return
        }

        scheduleSearchTask(delay: .zero, term: trimmedTerm, podcastUuid: podcastUuid)
    }

    func cancelPendingSearch() {
        searchTask?.cancel()
        searchTask = nil
    }

    func clearResults() {
        cancelPendingSearch()
        clearPendingSearchState()
        cancelPreloadTask()
    }

    private func clearPendingSearchState() {
        isSearchInFlight = false
        episodes = []
        currentEpisodeSearchTerm = ""
        currentSearchPodcastUUID = nil
    }

    private func scheduleSearchTask(delay: Duration, term: String, podcastUuid: String) {
        isSearchInFlight = true
        searchTask = Task { [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.performSearch(term: term, podcastUuid: podcastUuid)
        }
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

    func updateEpisodesFromSearchResults(
        _ results: [EpisodeSearchResult],
        selectedPodcastUUID: String?,
        trimmedSearchText: String
    ) {
        guard shouldApplySearchResults(selectedPodcastUUID: selectedPodcastUUID, trimmedSearchText: trimmedSearchText),
              let selectedPodcastUUID else {
            return
        }

        let filtered = results.filter { $0.podcastUuid == selectedPodcastUUID }
        let available = filtered.filter { !playlistEpisodeUUIDs.contains($0.uuid) }
        episodes = available
        isSearchInFlight = false
    }

    func handleSearchError(_ error: Error?, selectedPodcastUUID: String?, trimmedSearchText: String) {
        guard error != nil,
              shouldApplySearchResults(selectedPodcastUUID: selectedPodcastUUID, trimmedSearchText: trimmedSearchText) else {
            return
        }
        isSearchInFlight = false
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

    private func shouldApplySearchResults(selectedPodcastUUID: String?, trimmedSearchText: String) -> Bool {
        guard let selectedPodcastUUID,
              let currentSearchPodcastUUID,
              currentSearchPodcastUUID == selectedPodcastUUID else {
            return false
        }

        guard trimmedSearchText.count >= 2 else {
            return false
        }

        return trimmedSearchText == currentEpisodeSearchTerm
    }

    private func performSearch(term: String, podcastUuid: String) async {
        currentEpisodeSearchTerm = term
        currentSearchPodcastUUID = podcastUuid
        episodes = []
        searchResultsModel.search(term: term)
    }
}
