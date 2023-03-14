import SwiftUI
import PocketCastsServer

struct SearchResultsListView: View {
    enum DisplayMode {
        case podcasts
        case episodes
    }

    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper

    @ObservedObject var searchResults: SearchResultsModel

    let searchHistory: SearchHistoryModel?

    var displayMode: DisplayMode

    var body: some View {
        VStack {
            ThemedDivider()
            ScrollViewIfNeeded {
                LazyVStack(spacing: 0) {
                    Section {
                        switch displayMode {
                        case .podcasts:
                            ForEach(searchResults.podcasts, id: \.self) { podcast in

                                SearchResultCell(episode: nil, podcast: podcast, searchHistory: searchHistory)
                            }

                        case .episodes:
                            ForEach(searchResults.episodes, id: \.self) { episode in

                                SearchResultCell(episode: episode, podcast: nil, searchHistory: searchHistory)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(displayMode == .podcasts ? L10n.discoverAllPodcasts : L10n.discoverAllEpisodes))
        }
        .padding(.bottom, (PlaybackManager.shared.currentEpisode() != nil) ? Constants.Values.miniPlayerOffset : 0)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            searchAnalyticsHelper.trackListShown()
        }
    }
}

struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsListView(searchResults: SearchResultsModel(), searchHistory: nil, displayMode: .podcasts)
    }
}
