import Foundation
import SwiftUI

protocol SearchResultsDelegate {
    func clearSearch()
    func performLocalSearch(searchTerm: String)
    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void))
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void))
}

class SearchResults: ObservableObject {
    @Published var podcasts: [PodcastSearchResult] = []
    @Published var episodes: [EpisodeSearchResult] = []
}

class SearchResultsViewController: UIHostingController<AnyView> {
    let podcastSearch = PodcastSearchTask()
    let episodeSearch = EpisodeSearchTask()

    private var displaySearch: SearchVisibilityModel = SearchVisibilityModel()
    private var searchResults = SearchResults()

    init() {
        super.init(rootView: AnyView(SearchView(displaySearch: displaySearch, searchResults: searchResults).setupDefaultEnvironment()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchResultsViewController: SearchResultsDelegate {
    func clearSearch() {
        displaySearch.isSearching = false
        print("clear search")
    }

    func performLocalSearch(searchTerm: String) {
        displaySearch.isSearching = true
        print("local search: \(searchTerm)")
    }

    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void)) {
        displaySearch.isSearching = true
        print("remote search: \(searchTerm)")
        completion()
    }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        displaySearch.isSearching = true
        Task.init {
            let results = try? await podcastSearch.search(term: searchTerm)
            searchResults.podcasts = results ?? []
            completion()
        }

        Task.init {
            let results = try! await episodeSearch.search(term: searchTerm)
            searchResults.episodes = results
            completion()
        }
    }
}
