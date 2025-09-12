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
    @State var displayMode: SearchResultsListView.DisplayMode = .podcasts

    var body: some View {
        Group {
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
            } else {
                List {
                    Section {
                        podcastList
                    }
                    if !searchResults.hideEpisodes {
                        Section {
                            episodeList
                        }
                    }
                }.listStyle(.plain)
            }
        }
    }

    @ViewBuilder var episodeList: some View {
//        if !searchResults.hideEpisodes {
//            if searchResults.isSearchingForEpisodes {
//                ProgressView()
//                .frame(maxWidth: .infinity)
//                .tint(AppTheme.loadingActivityColor().color)
//                // Force the list to re-render the ProgressView by changing it's id
//                .id(identifier)
//                .onAppear {
//                    identifier += 1
//                }
//            } else if let _ = searchResults.episodeSearchError {
//                EmptyStateView(
//                    title: L10n.discoverSearchFailed,
//                    message: L10n.discoverSearchFailedMsg,
//                    icon: { Image("no-connection-grey").renderingMode(.template) },
//                    actions: [
//                        .init(title: L10n.tryAgain, style: SimpleTextButtonStyle(theme: .sharedTheme, textColor: .primaryInteractive01)) {
//                            searchResults.search(term: searchResults.currentSearchTerm)
//                        }
//                    ]
//                )
//            } else if searchResults.episodes.count > 0 {
                ForEach(searchResults.episodes.prefix(Constants.maxNumberOfEpisodes), id: \.self) { episode in
                    let played = searchResults.playedEpisodesUUIDs.contains(episode.uuid)
                    SearchResultCell(episode: episode, result: nil, played: played)
                }
//            } else if !searchResults.isShowingLocalResultsOnly {
//                EmptyStateView(title: L10n.discoverNoEpisodesFound,
//                               message: L10n.discoverNoPodcastsFoundMsg,
//                               icon: { Image(systemName: "info.circle") })
//            }
//        }
    }

    @ViewBuilder var podcastList: some View {
//        if searchResults.isSearchingForPodcasts {
//            ProgressView()
//                .frame(maxWidth: .infinity)
//                .tint(AppTheme.loadingActivityColor().color)
//            // Force the list to re-render the ProgressView by changing it's id
//                //.id(identifier)
//                .onAppear {
//                    //identifier += 1
//                }
//        } else if let _ = searchResults.podcastSearchError {
//            EmptyStateView(
//                title: L10n.discoverSearchFailed,
//                message: L10n.discoverSearchFailedMsg,
//                icon: { Image("no-connection-grey").renderingMode(.template) },
//                actions: [
//                    .init(title: L10n.tryAgain, style: SimpleTextButtonStyle(theme: .sharedTheme, textColor: .primaryInteractive01)) {
//                        searchResults.search(term: searchResults.currentSearchTerm)
//                    }
//                ]
//            )
//        } else if searchResults.podcasts.count > 0 {
//            VStack {
                ForEach(searchResults.podcasts.prefix(Constants.maxNumberOfEpisodes), id: \.self) { podcast in
                    PodcastTableCellView(viewModel: PodcastCellViewModel(podcastSearchResult: podcast), style: .large)
                        .padding(.vertical, 8)
                }
//            }.padding(20)
//        } else if !searchResults.isShowingLocalResultsOnly {
//            EmptyStateView(title: L10n.discoverNoPodcastsFound,
//                           message: L10n.discoverNoPodcastsFoundMsg,
//                           icon: { Image(systemName: "info.circle") })
//        }
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
