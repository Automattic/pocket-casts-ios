import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

class SearchResultsModel: ObservableObject {
    private let podcastSearch = PodcastSearchTask()
    private let episodeSearch = EpisodeSearchTask()
    private let predictiveSearch = PredictiveSearchTask()
    private let combinedSearch = CombinedSearchTask()

    private let analyticsHelper: SearchAnalyticsHelper

    @Published var isShowingPredictiveSearch = false
    @Published var isSearchingPredictive = false

    @Published var isSearchingForPodcasts = false
    @Published var isSearchingForEpisodes = false

    @Published var episodeSearchError: Error?
    @Published var podcastSearchError: Error?
    @Published var predictiveSearchError: Error?

    @Published var podcasts: [PodcastFolderSearchResult] = []
    @Published var episodes: [EpisodeSearchResult] = []
    @Published var predictive: [PredictiveSearchResult] = []
    @Published var combinedResults: [CombinedSearchResultType] = []

    @Published var isShowingLocalResultsOnly = false
    @Published var resultsContainLocalPodcasts = false

    @Published var hideEpisodes = false

    private(set) var currentSearchTerm: String = ""
    private(set) var currentPredictiveSearchTerm: String = ""

    private(set) var playedEpisodesUUIDs = Set<String>()
    private let dataMangager: DataManager

    let showLocalResults: Bool

    init(analyticsHelper: SearchAnalyticsHelper = SearchAnalyticsHelper(source: .unknown), showLocalResults: Bool = false,
         dataManager: DataManager = DataManager.sharedManager) {
        self.analyticsHelper = analyticsHelper
        self.dataMangager = dataManager
        self.showLocalResults = showLocalResults
    }

    var noResults: Bool {
        return podcasts.isEmpty && episodes.isEmpty && predictive.isEmpty && combinedResults.isEmpty
    }

    func clearSearch() {
        podcasts = []
        episodes = []
        combinedResults = []
        playedEpisodesUUIDs = []
        resultsContainLocalPodcasts = false
        currentSearchTerm = ""
    }

    @MainActor
    func predictiveSearch(term: String) {
        currentSearchTerm = term
        episodeSearchError = nil
        podcastSearchError = nil

        guard term.count > 1, !isTermAnURL(term) else {
            return
        }

        Task {
            isSearchingPredictive = true
            do {
                let results = try await predictiveSearch.search(term: term)
                show(predictiveResults: results)
                currentPredictiveSearchTerm = term
            } catch {
                predictiveSearchError = error
                analyticsHelper.trackPredictiveFailed(error)
            }
            isSearchingPredictive = false
        }
    }

    private func isTermAnURL(_ term: String) -> Bool {
        return term.lowercased().startsWith(string: "http://") || term.lowercased().startsWith(string: "https://")
    }

    @MainActor
    func search(term: String) {
        if FeatureFlag.searchImprovements.enabled, !isTermAnURL(term) {
            combinedSearch(term: term)
            return
        }

        currentSearchTerm = term
        episodeSearchError = nil
        podcastSearchError = nil

        if !isShowingLocalResultsOnly {
            clearSearch()
        }

        Task {
            isSearchingForPodcasts = true
            do {
                let results = try await podcastSearch.search(term: term)
                show(podcastResults: results)
            } catch {
                podcastSearchError = error
                analyticsHelper.trackFailed(error)
            }

            isSearchingForPodcasts = false
        }

        if !isTermAnURL(term) {
            hideEpisodes = false
            Task {
                isSearchingForEpisodes = true
                do {
                    let results = try await episodeSearch.search(term: term)
                    playedEpisodesUUIDs = buildPlayedEpisodesUUIDs(results)
                    episodes = results
                } catch {
                    episodeSearchError = error
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
    func combinedSearch(term: String) {
        currentSearchTerm = term
        episodeSearchError = nil
        podcastSearchError = nil

        if !isShowingLocalResultsOnly {
            clearSearch()
        }

        Task {
            isSearchingForPodcasts = true
            do {
                let results = try await combinedSearch.search(term: term)
                showCombinedResults(results)
            } catch {
                podcastSearchError = error
                analyticsHelper.trackFailed(error)
            }

            isSearchingForPodcasts = false
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
        return dataMangager.findPlayedEpisodes(uuids: uuids)
            .reduce(Set<String>()) { list, uuid in
                var set = list
                set.insert(uuid)
                return set
        }
    }

    private func show(podcastResults: [PodcastFolderSearchResult]) {
        isShowingPredictiveSearch = false
        if isShowingLocalResultsOnly {
            podcasts.append(contentsOf: podcastResults.filter { !podcasts.contains($0) })
            isShowingLocalResultsOnly = false
        } else {
            podcasts = podcastResults
        }
    }

    private func show(predictiveResults: [PredictiveSearchResult]) {
        isShowingPredictiveSearch = true
        predictive = predictiveResults
    }

    private func showCombinedResults(_ results: [CombinedSearchResultType]) {
        isShowingPredictiveSearch = false
        combinedResults = results
    }
}
