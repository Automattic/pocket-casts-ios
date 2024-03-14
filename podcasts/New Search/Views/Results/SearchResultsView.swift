import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @State var identifier = 0

    @State var showInlineResults = false
    @State var displayMode: SearchResultsListView.DisplayMode = .podcasts

    var body: some View {
        Group {
            NavigationLink(destination: SearchResultsListView(displayMode: displayMode).setupDefaultEnvironment().environmentObject(searchAnalyticsHelper).environmentObject(searchResults).environmentObject(searchHistory), isActive: $showInlineResults) { EmptyView() }

            SearchListView {
                ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll) {
                    displayMode = .podcasts
                    showInlineResults = true
                }

                PodcastsCarouselView()

                if !searchResults.hideEpisodes {
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
                        .tint(AppTheme.loadingActivityColor().color)
                        // Force the list to re-render the ProgressView by changing it's id
                        .id(identifier)
                        .onAppear {
                            identifier += 1
                        }
                    } else if searchResults.episodes.count > 0 {
                        ForEach(searchResults.episodes.prefix(Constants.maxNumberOfEpisodes), id: \.self) { episode in
                            let played = searchResults.playedEpisodesUUIDs.contains(episode.uuid)
                            SearchResultCell(episode: episode, result: nil, played: played)
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
                    }
                }
            }
        }
    }

    enum Constants {
        static let maxNumberOfEpisodes = 20
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView()
            .previewWithAllThemes()
    }
}
