import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

enum SearchScope: String, CaseIterable {
    case all = "All"
    case podcasts = "Podcasts"
    case episodes = "Episodes"
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
    var results: [CombinedSearchResultType] { get }
    var searchHistory: [String] { get }
    var autoCompleteSuggestions: [String] { get }

    func search(query: String)

    func autoComplete(query: String)

    func saveHistory(_ term: String)
}

@Observable
class SearchViewModel: SearchableViewModel {

    private var dataManager: DataManager
    private var searchModel: SearchHistoryModel
    private var predictiveSearchTask = PredictiveSearchTask()

    init(dataManager: DataManager = DataManager.sharedManager, searchModel: SearchHistoryModel = SearchHistoryModel()) {
        self.dataManager = dataManager
        self.searchModel = searchModel
    }

    var searchTerm: String = ""

    var state: SearchState = .query

    var scope: SearchScope = .all

    var results: [CombinedSearchResultType] = []

    var searchHistory: [String] {
        searchModel.entries.compactMap { entry in
            return entry.searchTerm
        }
    }

    func saveHistory(_ term: String) {
        searchModel.add(searchTerm: term)
    }

    var autoCompleteSuggestions: [String] = []

    private var searchTask: Task<Void, Never>?

    func search(query: String) {
        searchTerm = query
        // Cancel any previous task
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            autoCompleteSuggestions = []
            state = .query
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard !Task.isCancelled else { return }

            state = .searching
            var combinedResults: [CombinedSearchResultType] = []
            var suggestions: [String] = []
            do {
                let searchResults = try await predictiveSearchTask.search(term: query)
                guard !Task.isCancelled else { return }
                for searchResult in searchResults {
                    switch searchResult.type {
                    case .term(let word):
                        suggestions.append(word)
                    case .podcast(let podcastResult):
                        if let podcastResult = PodcastFolderSearchResult(from: searchResult) {
                            combinedResults.append(CombinedSearchResultType.podcast(podcastResult))
                        }
                    default:
                        continue
                    }
                }
                await MainActor.run { [combinedResults, suggestions] in
                    state = searchResults.isEmpty ? .empty : .results
                    results = combinedResults
                    autoCompleteSuggestions = suggestions
                }
            }  catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                state  = .error(error)
            }
        }
    }

    func autoComplete(query: String) {
                
    }

    private func fetchPodcasts(query: String) async throws -> [Podcast] {
        return dataManager.searchPodcasts(term: query)
    }
}
