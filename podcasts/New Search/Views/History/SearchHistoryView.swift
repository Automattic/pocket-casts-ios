import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme

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

            List {
                if !searchHistory.entries.isEmpty {
                    ThemeableListHeader(title: L10n.searchRecent, actionTitle: L10n.historyClearAll) {
                        withAnimation {
                            searchHistory.removeAll()
                        }
                    }

                    Section {
                        ForEach(searchHistory.entries, id: \.self) { entry in
                            SearchHistoryCell(entry: entry, searchHistory: searchHistory, searchResults: searchResults, displaySearch: displaySearch)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listSectionSeparator(.hidden)
                        }
                    }
                }
            }
        }
        .background(AppTheme.color(for: .primaryUi04, theme: theme))
        .listStyle(.plain)
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView(searchHistory: SearchHistoryModel(), searchResults: SearchResultsModel(), displaySearch: SearchVisibilityModel())
            .previewWithAllThemes()
    }
}
