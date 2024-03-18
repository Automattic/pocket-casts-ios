import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

class SearchResultsModel: ObservableObject {
    private let podcastSearch = PodcastSearchTask()
    private let episodeSearch = EpisodeSearchTask()

    private let analyticsHelper: SearchAnalyticsHelper

    @Published var isSearchingForPodcasts = false
    @Published var isSearchingForEpisodes = false

    @Published var podcasts: [PodcastFolderSearchResult] = []
    @Published var episodes: [EpisodeSearchResult] = []

    @Published var isShowingLocalResultsOnly = false
    @Published var resultsContainLocalPodcasts = false

    @Published var hideEpisodes = false

    private(set) var playedEpisodesUUIDs = Set<String>()
    private let dataMangager: DataManager

    init(analyticsHelper: SearchAnalyticsHelper = SearchAnalyticsHelper(source: .unknown),
         dataManager: DataManager = DataManager.sharedManager) {
        self.analyticsHelper = analyticsHelper
        self.dataMangager = dataManager
    }

    func clearSearch() {
        podcasts = []
        episodes = []
        playedEpisodesUUIDs = []
        resultsContainLocalPodcasts = false
    }

    @MainActor
    func search(term: String) {
        if !isShowingLocalResultsOnly {
            clearSearch()
        }

        Task {
            isSearchingForPodcasts = true
            do {
                let results = try await podcastSearch.search(term: term)
                show(podcastResults: results)
            } catch {
                analyticsHelper.trackFailed(error)
            }

            isSearchingForPodcasts = false
        }

        if !term.startsWith(string: "http") {
            hideEpisodes = false
            Task {
                isSearchingForEpisodes = true
                do {
                    let results = try await episodeSearch.search(term: term)
                    playedEpisodesUUIDs = buildPlayedEpisodesUUIDs(results)
                    episodes = results
                } catch {
                    analyticsHelper.trackFailed(error)
                }

                isSearchingForEpisodes = false
            }
        } else {
            hideEpisodes = true
        }

        analyticsHelper.trackSearchPerformed()
    }

    @MainActor
    func searchLocally(term searchTerm: String) {
        clearSearch()

        let allPodcasts = dataMangager.allPodcasts(includeUnsubscribed: false)

        var results = [PodcastFolderSearchResult?]()
        for podcast in allPodcasts {
            guard let title = podcast.title else { continue }

            if title.localizedCaseInsensitiveContains(searchTerm) {
                results.append(PodcastFolderSearchResult(from: podcast))
            } else if let author = podcast.author, author.localizedCaseInsensitiveContains(searchTerm) {
                results.append(PodcastFolderSearchResult(from: podcast))
            }
        }

        if SubscriptionHelper.hasActiveSubscription() {
            let allFolders = dataMangager.allFolders()
            for folder in allFolders {
                if folder.name.localizedCaseInsensitiveContains(searchTerm) {
                    results.append(PodcastFolderSearchResult(from: folder))
                }
            }
        }

        self.podcasts = results.compactMap { $0 }

        resultsContainLocalPodcasts = true
        isShowingLocalResultsOnly = true
    }

    private func buildPlayedEpisodesUUIDs(_ episodes: [EpisodeSearchResult]) -> Set<String> {
        if episodes.isEmpty {
            return []
        }
        let uuids = episodes.map { $0.uuid }
        return dataMangager.findPlayedEpisodesBy(uuids: uuids)
            .reduce(Set<String>()) { list, episode in
                var set = list
                set.insert(episode.uuid)
                return set
        }
    }

    private func show(podcastResults: [PodcastFolderSearchResult]) {
        if isShowingLocalResultsOnly {
            podcasts.append(contentsOf: podcastResults.filter { !podcasts.contains($0) })
            isShowingLocalResultsOnly = false
        } else {
            podcasts = podcastResults
        }
    }
}
