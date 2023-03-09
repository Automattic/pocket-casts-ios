import Foundation
import SwiftUI

protocol SearchResultsDelegate {
    func clearSearch()
    func performLocalSearch(searchTerm: String)
    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void))
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void))
}

extension SearchResultsDelegate {
    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void)) {}
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {}
}

class SearchResultsViewController: UIHostingController<AnyView> {
    private var displaySearch: SearchVisibilityModel = SearchVisibilityModel()
    private var searchResults = SearchResultsModel()

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
        searchResults.search(term: searchTerm)
        completion()
    }
}
