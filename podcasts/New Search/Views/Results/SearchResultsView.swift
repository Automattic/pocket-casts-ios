import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResults

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            List {
                ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll)

                Section {
                    PodcastsCarouselView(searchResults: searchResults)
                }

                ThemeableListHeader(title: L10n.episodes, actionTitle: L10n.discoverShowAll)

                Section {
                    ForEach(0..<searchResults.episodes.count, id: \.self) { index in

                        SearchEpisodeCell(episode: searchResults.episodes[index])
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listSectionSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
        }
        .applyDefaultThemeOptions()
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(searchResults: SearchResults())
            .previewWithAllThemes()
    }
}
