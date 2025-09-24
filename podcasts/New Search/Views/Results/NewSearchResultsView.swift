import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct NewSearchResultsView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @State var identifier = 0

    @State var showInlineResults = false
    @State var displayMode: SearchResultsListView.DisplayMode = .allResults

    var body: some View {
        ZStack {
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
                .background(Theme.sharedTheme.primaryUi01)
            } else if searchResults.isSearchingForEpisodes || searchResults.isSearchingForPodcasts {
                  ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(AppTheme.loadingActivityColor().color)
            } else if searchResults.noResults {
                HStack(alignment: .center) {
                    EmptyStateView(title: L10n.discoverNoPodcastsFound,
                                   message: L10n.discoverNoPodcastsFoundMsg,
                                   icon: { Image(systemName: "info.circle") })
                }
                .frame(maxHeight: .infinity)
                .background(Theme.sharedTheme.primaryUi01)
            } else {
                VStack {
                    filterPicker
                    List {
                        if displayMode == .allResults || displayMode == .podcasts {
                            Section {
                                podcastList
                            }
                        }
                        if displayMode == .allResults || displayMode == .episodes {
                            Section {
                                episodeList
                            }
                        }
                    }
                    .listStyle(.plain)
                    .listRowSeparatorTint(theme.primaryUi05)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .background(theme.primaryUi01.ignoresSafeArea())
    }

    @ViewBuilder var filterPicker: some View {
        PillSegmentControl(SearchResultsListView.DisplayMode.allCases, selection: $displayMode) { item in
            Text(item.localizedDescription)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder var podcastList: some View {
        ForEach(searchResults.podcasts.prefix(Constants.maxNumberOfEpisodes), id: \.self) { podcast in
            SearchResultCell(episode: nil, result: podcast, played: false, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                .listRowBackground(theme.primaryUi01)
                .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                    return 0
                }
        }
    }

    @ViewBuilder var episodeList: some View {
        ForEach(searchResults.episodes.prefix(Constants.maxNumberOfEpisodes), id: \.self) { episode in
            let played = searchResults.playedEpisodesUUIDs.contains(episode.uuid)
            SearchResultCell(episode: episode, result: nil, played: played, showDivider: false, cellStyle: ListCellButtonStyle(backgroundStyle: .primaryUi01))
                .listRowBackground(theme.primaryUi01)
                .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                    return 0
                }
        }
    }

    enum Constants {
        static let maxNumberOfEpisodes = 20
    }
}

struct NewSearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView()
            .previewWithAllThemes()
    }
}
