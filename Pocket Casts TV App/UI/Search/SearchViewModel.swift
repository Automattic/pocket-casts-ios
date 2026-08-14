import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

enum SearchScope: CaseIterable, Equatable {
    case topResults
    case podcasts
    case episodes

    var localizedName: String {
        switch self {
        case .topResults:
            return L10n.tvSearchScopeTopResults
        case .podcasts:
            return L10n.podcastsPlural
        case .episodes:
            return L10n.episodes
        }
    }

    /// Matches the iOS `SearchDisplayMode` analytics values.
    var analyticsDescription: String {
        switch self {
        case .topResults:
            return "top_results"
        case .podcasts:
            return "podcasts"
        case .episodes:
            return "episodes"
        }
    }
}

enum SearchState: Equatable {
    case query
    case searching
    case results
    case error(Error)
    case empty

    static func == (lhs: SearchState, rhs: SearchState) -> Bool {
        switch (lhs, rhs) {
        case (.query, .query),
             (.searching, .searching),
             (.results, .results),
             (.empty, .empty):
            return true
        case let (.error(lhsError), .error(rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        default:
            return false
        }
    }
}

protocol SearchableViewModel: AnyObject, Observation.Observable {
    var searchTerm: String { get }
    var state: SearchState { get }
    var scope: SearchScope { get set }
    var podcastResults: [CombinedSearchResultType] { get }
    var episodeResults: [EpisodeSearchResult] { get }

    /// `episodeResults` split into the episodes the `Featured` row previews and the
    /// ones left for the `Episodes` row. Partitioned once per search rather than on
    /// every render.
    var videoEpisodeResults: [EpisodeSearchResult] { get }
    var remainingEpisodeResults: [EpisodeSearchResult] { get }

    var searchHistory: [String] { get }
    var autoCompleteSuggestions: [String] { get }

    func search(query: String)

    func saveHistory(_ term: String)

    func playEpisode(_ episode: EpisodeSearchResult) async -> Bool

    var isInSearchMode: Bool { get }
}

extension SearchableViewModel {
    /// `podcastResults` only ever holds `.podcast` cases — this unwraps them for the
    /// rows that take a podcast directly.
    var podcastOnlyResults: [PodcastFolderSearchResult] {
        podcastResults.compactMap {
            guard case .podcast(let podcast) = $0 else { return nil }
            return podcast
        }
    }
}

extension EpisodeSearchResult {
    /// A video episode we also have a stream for — the only kind the `Featured` row can preview.
    var isPlayableVideo: Bool {
        hasVideo && videoURL != nil
    }
}

@Observable
@MainActor
class SearchViewModel: SearchableViewModel {

    private var dataManager: DataManager
    private var tvDataManager: TVDataManager
    private var searchModel: SearchHistoryModel
    private var predictiveSearchTask = PredictiveSearchTask()
    private var fullSearchTask = CombinedSearchTask()

    init(dataManager: DataManager = DataManager.sharedManager, tvDataManager: TVDataManager = TVDataManager.shared, searchModel: SearchHistoryModel = SearchHistoryModel.shared) {
        self.dataManager = dataManager
        self.tvDataManager = tvDataManager
        self.searchModel = searchModel
    }

    var isInSearchMode: Bool {
        switch state {
        case .query:
            false
        default:
            true
        }
    }

    var searchTerm: String = ""

    var state: SearchState = .query

    var scope: SearchScope = .topResults

    var podcastResults: [CombinedSearchResultType] = []

    // Partitioned here rather than in the view so the filtering runs once per search
    // instead of on every render, and the two halves can't drift from `episodeResults`.
    var episodeResults: [EpisodeSearchResult] = [] {
        didSet {
            videoEpisodeResults = episodeResults.filter(\.isPlayableVideo)
            remainingEpisodeResults = episodeResults.filter { !$0.isPlayableVideo }
        }
    }

    private(set) var videoEpisodeResults: [EpisodeSearchResult] = []

    private(set) var remainingEpisodeResults: [EpisodeSearchResult] = []

    var searchHistory: [String] {
        searchModel.entries.compactMap(\.searchTerm)
    }

    func saveHistory(_ term: String) {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        searchModel.add(searchTerm: term.trimmingCharacters(in: .whitespaces))
    }

    var autoCompleteSuggestions: [String] = []

    private var searchTask: Task<Void, Never>?

    func search(query: String) {
        searchTerm = query
        // Cancel any previous task
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            if !podcastResults.isEmpty { podcastResults = [] }
            if !autoCompleteSuggestions.isEmpty { autoCompleteSuggestions = [] }
            state = .query
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            var uuids: Set<String> = []
            state = .searching
            Analytics.track(.searchPerformed, properties: ["source": "search"])
            var combinedPodcastsResults: [CombinedSearchResultType] = []
            var suggestions: [String] = []
            do {
                let searchResults = try await predictiveSearchTask.search(term: query)
                guard !Task.isCancelled else { return }

                for searchResult in searchResults {
                    switch searchResult.type {
                    case .term(let word):
                        suggestions.append(word)
                    case .podcast:
                        if let podcastResult = PodcastFolderSearchResult(from: searchResult) {
                            uuids.insert(podcastResult.uuid)
                            combinedPodcastsResults.append(CombinedSearchResultType.podcast(podcastResult))
                        }
                    default:
                        continue
                    }
                }

                let localPodcasts = try await searchLocalPodcasts(query: query)
                for localPodcast in localPodcasts {
                    if !uuids.contains(localPodcast.uuid), let podcastResult = PodcastFolderSearchResult(from: localPodcast) {
                        combinedPodcastsResults.append(CombinedSearchResultType.podcast(podcastResult))
                        uuids.insert(podcastResult.uuid)
                    }
                }

                state = combinedPodcastsResults.isEmpty ? .empty : .results
                podcastResults = combinedPodcastsResults
                autoCompleteSuggestions = suggestions

                guard !Task.isCancelled else { return }
                saveHistory(query)
                let fullResults = try await fullSearchTask.search(term: query)
                var episodes: [EpisodeSearchResult] = []
                for searchResult in fullResults {
                    switch searchResult {
                    case .podcast(let podcast):
                        if !uuids.contains(podcast.uuid) {
                            combinedPodcastsResults.append(searchResult)
                        }
                    case .episode(let episode):
                        episodes.append(episode)
                    }
                }

                guard !Task.isCancelled else { return }

                podcastResults = combinedPodcastsResults
                episodeResults = episodes
                let isEmpty = combinedPodcastsResults.isEmpty && episodes.isEmpty
                if isEmpty {
                    Analytics.track(.searchEmptyResults, properties: ["source": "search", "term": query])
                }
                state = isEmpty ? .empty : .results
            }  catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                Analytics.track(.searchFailed, properties: ["source": "search", "error_code": (error as NSError).code])
                state  = .error(error)
            }
        }
    }

    private func searchLocalPodcasts(query: String) async throws -> [Podcast] {
        return dataManager.searchPodcasts(term: query)
    }

    func playEpisode(_ episode: EpisodeSearchResult) async -> Bool {
        AnalyticsPlaybackHelper.shared.currentSource = .search
        return await tvDataManager.playEpisode(episode)
    }
}
