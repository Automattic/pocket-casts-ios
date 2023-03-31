import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var displaySearch: SearchVisibilityModel

    var body: some View {
        SearchListView {
            if !searchHistory.entries.isEmpty {
                ThemeableListHeader(title: L10n.searchRecent, actionTitle: L10n.historyClearAll) {
                    withAnimation {
                        searchHistory.removeAll()
                        searchAnalyticsHelper.trackHistoryCleared()
                    }
                }

                ForEach(searchHistory.entries, id: \.self) { entry in
                    SearchHistoryCell(entry: entry)
                }
            }
        }
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView()
            .previewWithAllThemes()
    }
}
