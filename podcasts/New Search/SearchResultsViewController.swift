import Foundation
import SwiftUI

protocol SearchResultsDelegate {
    func clearSearch()
    func performLocalSearch(searchTerm: String)
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void))
}

extension SearchResultsDelegate {
    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void)) {}
    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {}
}

class SearchResultsViewController: UIHostingController<AnyView> {
    private let displaySearch: SearchVisibilityModel = SearchVisibilityModel()
    private let searchHistoryModel: SearchHistoryModel = SearchHistoryModel.shared
    private let searchResults: SearchResultsModel
    private let searchAnalyticsHelper: SearchAnalyticsHelper

    init(source: AnalyticsSource) {
        searchAnalyticsHelper = SearchAnalyticsHelper(source: source)
        self.searchResults = SearchResultsModel(analyticsHelper: searchAnalyticsHelper)
        super.init(rootView: AnyView(
            SearchView()
            .setupDefaultEnvironment()
            .environmentObject(searchAnalyticsHelper)
            .environmentObject(searchResults)
            .environmentObject(searchHistoryModel)
            .environmentObject(displaySearch))
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchResultsViewController: SearchResultsDelegate {
    func clearSearch() {
        displaySearch.isSearching = false
        searchResults.clearSearch()
    }

    func performLocalSearch(searchTerm: String) {
        displaySearch.isSearching = true
        searchResults.searchLocally(term: searchTerm)
    }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        displaySearch.isSearching = true
        searchResults.search(term: searchTerm)

        if !triggeredByTimer {
            searchHistoryModel.add(searchTerm: searchTerm)
        }

        completion()
    }
}
