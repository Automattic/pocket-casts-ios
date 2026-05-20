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
    var state: SearchState { get }
    var scope: SearchScope { get set }
    var podcastUuids: [String] { get }
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

    var state: SearchState = .query

    var scope: SearchScope = .all

    var podcastUuids: [String] = []

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
        // Cancel any previous task
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            podcastUuids = []
            autoCompleteSuggestions = []
            state = .query
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard !Task.isCancelled else { return }

            state = .searching
            var podcasts: [String] = []
            var suggestions: [String] = []
            do {
                let searchResults = try await predictiveSearchTask.search(term: query)
                guard !Task.isCancelled else { return }
                for searchResult in searchResults {
                    switch searchResult.type {
                    case .term(let word):
                        suggestions.append(word)
                    case .podcast(let podcastResult):
                        podcasts.append(podcastResult.uuid)
                    default:
                        continue
                    }
                }
                await MainActor.run { [podcasts, suggestions] in
                    state = podcastUuids.isEmpty ? .empty : .results
                    podcastUuids = podcasts
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
