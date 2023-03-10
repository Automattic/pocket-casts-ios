import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    let searchHistory: SearchHistoryModel

    @State var identifier = 0

    @State var showAllPodcasts = false

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            NavigationLink(destination: PodcastResultsView(searchResults: searchResults).setupDefaultEnvironment(), isActive: $showAllPodcasts) { EmptyView() }

            List {
                ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll) {
                    showAllPodcasts = true
                }

                Section {
                    PodcastsCarouselView(searchResults: searchResults, searchHistory: searchHistory)
                }

                ThemeableListHeader(title: L10n.episodes, actionTitle: nil)

                if searchResults.isSearchingForEpisodes {
                    ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                    // Force the list to re-render the ProgressView by changing it's id
                    .id(identifier)
                    .onAppear {
                        identifier += 1
                    }
                } else if searchResults.episodes.count > 0 {
                    Section {
                        ForEach(searchResults.episodes, id: \.self) { episode in

                            SearchEpisodeCell(episode: episode, podcast: nil, searchHistory: searchHistory)
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
        SearchResultsView(searchResults: SearchResultsModel(), searchHistory: SearchHistoryModel())
            .previewWithAllThemes()
    }
}
