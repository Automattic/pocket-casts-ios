import SwiftUI

class SearchVisibilityModel: ObservableObject {
    @Published var isSearching = false
}

struct SearchView: View {
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var displaySearch: SearchVisibilityModel
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @State var isMiniPlayerVisible: Bool = false

    var body: some View {
        searchView
        .padding(.bottom, isMiniPlayerVisible ? Constants.Values.miniPlayerOffset : 0)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            isMiniPlayerVisible = (PlaybackManager.shared.currentEpisode() != nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidAppear), perform: { _ in
            isMiniPlayerVisible = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidDisappear), perform: { _ in
            isMiniPlayerVisible = false
        })
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
