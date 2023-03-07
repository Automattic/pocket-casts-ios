import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            List {
                ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll)

                Section {
                    PodcastsCarouselView(searchResults: searchResults)
                }

                ThemeableListHeader(title: L10n.episodes, actionTitle: L10n.discoverShowAll)

                if searchResults.isSearchingForEpisodes {
                    HStack(alignment: .center) {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                } else if searchResults.episodes.count > 0 {
                    Section {
                        ForEach(0..<searchResults.episodes.count, id: \.self) { index in

                            SearchEpisodeCell(episode: searchResults.episodes[index])
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listSectionSeparator(.hidden)
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Text(L10n.discoverNoEpisodesFound)
                            .font(style: .subheadline, weight: .medium)

                        Text(L10n.discoverNoPodcastsFoundMsg)
                            .font(size: 14, style: .subheadline, weight: .medium)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.all, 10)
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
        .applyDefaultThemeOptions()
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(searchResults: SearchResultsModel())
            .previewWithAllThemes()
    }
}
