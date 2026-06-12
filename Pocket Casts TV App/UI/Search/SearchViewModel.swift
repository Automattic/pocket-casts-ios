import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

enum SearchScope: CaseIterable {
    case podcasts
    case episodes

    var localizedName: String {
        switch self {
        case .podcasts:
            return L10n.podcastsPlural
        case .episodes:
            return L10n.episodes
        }
    }
}

enum SearchState {
    case query
    case searching
    case results
    case error(Error)
    case empty
}

protocol SearchableViewModel: AnyObject, Observation.Observable {
    var searchTerm: String { get }
    var state: SearchState { get }
    var scope: SearchScope { get set }
    var podcastResults: [CombinedSearchResultType] { get }
    var episodeResults: [EpisodeSearchResult] { get }
    var searchHistory: [String] { get }
    var autoCompleteSuggestions: [String] { get }

    func search(query: String)

    func saveHistory(_ term: String)

    func playEpisode(_ episode: EpisodeSearchResult) async -> Bool

    var isInSearchMode: Bool { get }
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

    var scope: SearchScope = .podcasts

    var podcastResults: [CombinedSearchResultType] = []

    var episodeResults: [EpisodeSearchResult] = []

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
                state = (combinedPodcastsResults.isEmpty && episodes.isEmpty) ? .empty : .results
            }  catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                state  = .error(error)
            }
        }
    }

    private func searchLocalPodcasts(query: String) async throws -> [Podcast] {
        return dataManager.searchPodcasts(term: query)
    }

    func playEpisode(_ episode: EpisodeSearchResult) async -> Bool {
        return await tvDataManager.playEpisode(episode)
    }
}
