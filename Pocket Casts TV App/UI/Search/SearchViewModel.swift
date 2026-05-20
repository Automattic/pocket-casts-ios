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

    func saveHistory(_ term: String)
}

@Observable
@MainActor
class SearchViewModel: SearchableViewModel {

    private var searchModel: SearchHistoryModel
    private var predictiveSearchTask = PredictiveSearchTask()

    init(searchModel: SearchHistoryModel = SearchHistoryModel.shared) {
        self.searchModel = searchModel
    }

    var searchTerm: String = ""

    var state: SearchState = .query

    var scope: SearchScope = .all

    var results: [CombinedSearchResultType] = []

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
            if !results.isEmpty { results = [] }
            if !autoCompleteSuggestions.isEmpty { autoCompleteSuggestions = [] }
            state = .query
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))
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
                    case .podcast:
                        if let podcastResult = PodcastFolderSearchResult(from: searchResult) {
                            combinedResults.append(CombinedSearchResultType.podcast(podcastResult))
                        }
                    default:
                        continue
                    }
                }
                state = combinedResults.isEmpty ? .empty : .results
                results = combinedResults
                autoCompleteSuggestions = suggestions
            }  catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                state  = .error(error)
            }
        }
    }
}
