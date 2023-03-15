import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper

    @ObservedObject var searchHistory: SearchHistoryModel

    let searchResults: SearchResultsModel
    let displaySearch: SearchVisibilityModel

    private var episode: Episode {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        return episode
    }

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !searchHistory.entries.isEmpty {
                        ThemeableListHeader(title: L10n.searchRecent, actionTitle: L10n.historyClearAll) {
                            withAnimation {
                                searchHistory.removeAll()
                                searchAnalyticsHelper.trackHistoryCleared()
                            }
                        }

                        ForEach(searchHistory.entries, id: \.self) { entry in
                            SearchHistoryCell(entry: entry, searchHistory: searchHistory, searchResults: searchResults, displaySearch: displaySearch)
                        }
                    }
                }
            }
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView(searchHistory: SearchHistoryModel(), searchResults: SearchResultsModel(), displaySearch: SearchVisibilityModel())
            .previewWithAllThemes()
    }
}
