import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    let searchHistory: SearchHistoryModel

    @State var identifier = 0

    @State var showInlineResults = false
    @State var displayMode: SearchResultsListView.DisplayMode = .podcasts

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()

            NavigationLink(destination: SearchResultsListView(searchResults: searchResults, searchHistory: searchHistory, displayMode: displayMode).setupDefaultEnvironment(), isActive: $showInlineResults) { EmptyView() }

            List {
                ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll) {
                    displayMode = .podcasts
                    showInlineResults = true
                }

                Section {
                    PodcastsCarouselView(searchResults: searchResults, searchHistory: searchHistory)
                }

                // If local results are being shown, we hide the episodes header
                if !searchResults.isShowingLocalResultsOnly {
                    ThemeableListHeader(title: L10n.episodes, actionTitle: searchResults.episodes.count > 20 ? L10n.discoverShowAll : nil) {
                        displayMode = .episodes
                        showInlineResults = true
                    }
                }

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
                        ForEach(searchResults.episodes.prefix(Constants.maxNumberOfEpisodes), id: \.self) { episode in

                            SearchResultCell(episode: episode, podcast: nil, searchHistory: searchHistory)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listSectionSeparator(.hidden)
                        }
                    }
                } else if !searchResults.isShowingLocalResultsOnly {
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

    enum Constants {
        static let maxNumberOfEpisodes = 20
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(searchResults: SearchResultsModel(), searchHistory: SearchHistoryModel())
            .previewWithAllThemes()
    }
}
