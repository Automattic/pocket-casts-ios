import SwiftUI

class SearchVisibilityModel: ObservableObject {
    @Published var isSearching = false
}

struct SearchView: View {
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var displaySearch: SearchVisibilityModel
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    var body: some View {
        searchView
        .ignoresSafeArea(.keyboard)
        .modifier(MiniPlayerPadding())
        .applyDefaultThemeOptions()
    }

    @ViewBuilder
    private var searchView: some View {
        if displaySearch.isSearching {
            SearchResultsView()
        } else {
            SearchHistoryView()
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
