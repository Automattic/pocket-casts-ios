import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResults

    private var episode: Episode {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        episode.publishedDate = Date()
        return episode
    }

    var body: some View {
        VStack(spacing: 0) {
            ThemeableSeparatorView()

            List {
                ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll)

                Section {
                    PodcastsCarouselView(searchResults: searchResults)
                }

                ThemeableListHeader(title: L10n.episodes, actionTitle: L10n.discoverShowAll)

                Section {
                    SearchEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
        SearchResultsView(searchResults: SearchResults())
            .previewWithAllThemes()
    }
}
