import SwiftUI
import PocketCastsDataModel

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
    var results: [Podcast] { get }
    var searchHistory: [String] { get }
    var autoCompleteSuggestions: [String] { get }

    func search(query: String)

    func autoComplete(query: String)
}

@Observable
@MainActor
class SearchViewModel: SearchableViewModel {

    private var dataManager: DataManager = DataManager.sharedManager

    var state: SearchState = .query

    var scope: SearchScope = .all

    var results: [Podcast] = []

    var searchHistory: [String] = ["Conan"]

    var autoCompleteSuggestions: [String] = []

    private var searchTask: Task<Void, Never>?

    func search(query: String) {
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

            do {
                let podcasts = try await fetchPodcasts(query: query)
                guard !Task.isCancelled else { return }
                results = podcasts
                state = results.isEmpty ? .empty : .results
            }  catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                state  = .error(error)
            }
        }
    }

    func autoComplete(query: String) {
        let podcasts = dataManager.searchPodcasts(term: query)
        autoCompleteSuggestions = podcasts.compactMap {
            $0.title
        }
    }

    private func fetchPodcasts(query: String) async throws -> [Podcast] {
        return dataManager.searchPodcasts(term: query)
    }
}
