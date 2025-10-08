import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils
import PocketCastsServer

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
            NavigationLink(destination:
                            SearchResultsListView(displayMode: displayMode)
                                .setupDefaultEnvironment()
                                .environmentObject(searchAnalyticsHelper)
                                .environmentObject(searchResults)
                                .environmentObject(searchHistory),
                           isActive: $showInlineResults) {
                EmptyView()
            }

            if searchResults.episodeSearchError != nil && searchResults.podcastSearchError != nil {
                HStack(alignment: .center) {
                    EmptyStateView(
                        title: L10n.discoverSearchFailed,
                        message: L10n.discoverSearchFailedMsg,
                        icon: { Image("no-connection-grey").renderingMode(.template) },
                        actions: [
                            .init(title: L10n.tryAgain, style: SimpleTextButtonStyle(theme: .sharedTheme, textColor: .primaryInteractive01)) {
                                searchResults.search(term: searchResults.currentSearchTerm)
                            }
                        ]
                    )
                }
                .frame(maxHeight: .infinity)
                .background(Theme.sharedTheme.primaryUi02)
            } else if searchResults.isShowingPredictiveSearch || searchResults.isSearchingPredictive {
                if searchResults.isSearchingPredictive, searchResults.predictive.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tint(AppTheme.loadingActivityColor().color)
                } else {
                    SearchListView {
                        PredictiveList()
                            .onAppear {
                                self.searchAnalyticsHelper.trackPredictiveShown()
                            }
                    }
                }
            } else {
                SearchListView {
                    ThemeableListHeader(title: L10n.podcastsPlural, actionTitle: L10n.discoverShowAll) {
                        displayMode = .podcasts
                        showInlineResults = true
                    }
                    PodcastsCarouselView()
                    episodeList()
                }
            }
        }
    }

    @ViewBuilder func episodeList() -> some View {
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
            } else if let _ = searchResults.episodeSearchError {
                EmptyStateView(
                    title: L10n.discoverSearchFailed,
                    message: L10n.discoverSearchFailedMsg,
                    icon: { Image("no-connection-grey").renderingMode(.template) },
                    actions: [
                        .init(title: L10n.tryAgain, style: SimpleTextButtonStyle(theme: .sharedTheme, textColor: .primaryInteractive01)) {
                            searchResults.search(term: searchResults.currentSearchTerm)
                        }
                    ]
                )
            } else if searchResults.episodes.count > 0 {
                ForEach(searchResults.episodes.prefix(Constants.maxNumberOfEpisodes), id: \.self) { episode in
                    let played = searchResults.playedEpisodesUUIDs.contains(episode.uuid)
                    SearchResultCell(episode: episode, result: nil, played: played)
                }
            } else if !searchResults.isShowingLocalResultsOnly {
                EmptyStateView(title: L10n.discoverNoEpisodesFound,
                               message: L10n.discoverNoPodcastsFoundMsg,
                               icon: { Image(systemName: "info.circle") })
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
