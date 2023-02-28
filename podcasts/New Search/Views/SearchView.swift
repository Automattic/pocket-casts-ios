import SwiftUI

class SearchVisibilityModel: ObservableObject {
    @Published var isSearching = false
}

struct SearchView: View {
    @ObservedObject var displaySearch: SearchVisibilityModel

    var body: some View {
        searchView
        .padding(.bottom, (PlaybackManager.shared.currentEpisode() != nil) ? Constants.Values.miniPlayerOffset : 0)
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
        SearchView(displaySearch: SearchVisibilityModel())
    }
}
