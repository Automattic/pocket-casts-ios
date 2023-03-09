import SwiftUI

class SearchVisibilityModel: ObservableObject {
    @Published var isSearching = false
}

struct SearchView: View {
    @ObservedObject var displaySearch: SearchVisibilityModel

    var searchResults: SearchResultsModel

    var searchHistory: SearchHistoryModel

    var body: some View {
        searchView
        .padding(.bottom, (PlaybackManager.shared.currentEpisode() != nil) ? Constants.Values.miniPlayerOffset : 0)
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var searchView: some View {
        if displaySearch.isSearching {
            SearchResultsView(searchResults: searchResults, searchHistory: searchHistory)
        } else {
            SearchHistoryView(searchHistory: searchHistory)
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(displaySearch: SearchVisibilityModel(), searchResults: SearchResultsModel(),
        searchHistory: SearchHistoryModel())
    }
}
