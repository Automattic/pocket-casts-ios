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

/// Apply a bottom padding whenever the mini player is visible
struct MiniPlayerPadding: ViewModifier {
    @State var isMiniPlayerVisible: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.bottom, isMiniPlayerVisible ? Constants.Values.miniPlayerOffset - 2 : 0).onAppear {
                isMiniPlayerVisible = (PlaybackManager.shared.currentEpisode() != nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidAppear), perform: { _ in
                isMiniPlayerVisible = true
            })
            .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.miniPlayerDidDisappear), perform: { _ in
                isMiniPlayerVisible = false
            })
    }
}
