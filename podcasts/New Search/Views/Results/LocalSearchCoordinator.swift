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
    private var currentEpisodeSearchTerm = ""
    private var currentSearchPodcastUUID: String?
    private var searchTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?

    init(
        playlist: EpisodeFilter,
        dataManager: DataManager = DataManager.sharedManager
    ) {
        self.playlist = playlist
        self.dataManager = dataManager
    }

    deinit {
        searchTask?.cancel()
    }

    func refreshPlaylistEpisodes() async {
        let uuids = await Task.detached { [dataManager, playlist] in
            let playlistEpisodes = dataManager.playlistEpisodes(for: playlist)
            return Set(playlistEpisodes.map { $0.uuid })
        }.value

        await MainActor.run {
            self.playlistEpisodeUUIDs = uuids
        }
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

            let results = await Task.detached { [dataManager] in
                let podcastEpisodes = dataManager.allEpisodesForPodcast(id: podcast.id)
                let sortedEpisodes = podcastEpisodes.sorted { lhs, rhs in
                    let lhsDate = lhs.publishedDate ?? lhs.addedDate ?? .distantPast
                    let rhsDate = rhs.publishedDate ?? rhs.addedDate ?? .distantPast
                    return lhsDate > rhsDate
                }
                return sortedEpisodes
            }.value

            await MainActor.run {
                let availableEpisodes = results.filter { !self.playlistEpisodeUUIDs.contains($0.uuid) }
                self.episodes = availableEpisodes.map { EpisodeSearchResult(episode: $0) }
                self.isSearchInFlight = false
            }
        }
    }

    @MainActor
    private func cancelPreloadTask() {
        preloadTask?.cancel()
        preloadTask = nil
    }

    func handleAddEpisode(_ searchResult: EpisodeSearchResult) {
        Task {
            let result = await Task.detached { [dataManager, playlist] in
                guard let episode = dataManager.findEpisode(uuid: searchResult.uuid) else {
                    return (didAdd: false, episode: nil as Episode?, isFull: false)
                }

                let didAdd = dataManager.add(episodes: [episode], to: playlist)
                playlist.syncStatus = SyncStatus.notSynced.rawValue
                dataManager.save(playlist: playlist)

                let isFull = !didAdd
                return (didAdd: didAdd, episode: episode, isFull: isFull)
            }.value

            guard let episode = result.episode else {
                assertionFailure("Episode should exist")
                return
            }

            Analytics.track(.filterAddEpisodesEpisodeTapped, properties: ["is_playlist_full": result.isFull])

            guard result.didAdd else {
                let theme: any ToastTheme = ToastIconTheme(iconName: "option-alert", iconColor: Theme.sharedTheme.primaryIcon01)
                Toast.show(L10n.playlistManualAddEpisodeFullPlaylistToast, theme: theme)
                return
            }

            // For now let's track the event directly here to avoid swift concurrency warning using the PlaylistTypeTrackerProvider
            Analytics.track(
                .episodeAddedToList,
                properties:
                    [
                        "source": "playlist_editor",
                        "playlist_name": playlist.playlistName,
                        "playlist_uuid": playlist.uuid,
                        "episode_uuid": episode.uuid,
                        "podcast_uuid": episode.podcastUuid
                    ]
            )

            await MainActor.run {
                self.playlistEpisodeUUIDs.insert(searchResult.uuid)
                self.episodes.removeAll { $0.uuid == searchResult.uuid }
                self.addedEpisodeCount += 1
            }
        }
    }

    private func performSearch(term: String, podcastUuid: String) async {
        await MainActor.run {
            self.currentEpisodeSearchTerm = term
            self.currentSearchPodcastUUID = podcastUuid
            self.episodes = []
        }

        let matchedEpisodes = await Task.detached {
            DataManager.sharedManager.findEpisodes(with: term, podcastUUID: podcastUuid)
        }.value

        guard !Task.isCancelled else {
            await MainActor.run {
                if self.currentEpisodeSearchTerm == term, self.currentSearchPodcastUUID == podcastUuid {
                    self.isSearchInFlight = false
                }
            }
            return
        }

        await MainActor.run {
            guard self.currentEpisodeSearchTerm == term,
                  self.currentSearchPodcastUUID == podcastUuid else {
                return
            }

            self.episodes = matchedEpisodes.map { EpisodeSearchResult(episode: $0) }
            self.isSearchInFlight = false
        }
    }
}
