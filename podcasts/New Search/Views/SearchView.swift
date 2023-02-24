import SwiftUI

class SearchVisibilityModel: ObservableObject {
    @Published var isSearching = false
}

struct SearchView: View {
    @ObservedObject var displaySearch: SearchVisibilityModel

    var searchResults: SearchResults

    var body: some View {
        if displaySearch.isSearching {
            SearchResultsView(searchResults: searchResults)
        } else {
            SearchHistoryView()
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(displaySearch: SearchVisibilityModel(), searchResults: SearchResults())
    }
}
