import SwiftUI
import PocketCastsServer

struct InlineResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    let searchHistory: SearchHistoryModel?

    /// If this view should show podcasts or episodes
    var showPodcasts = true

    var body: some View {
        VStack {
            ThemedDivider()
            ScrollViewIfNeeded {
                LazyVStack(spacing: 0) {
                    Section {
                        if showPodcasts {
                            ForEach(searchResults.podcasts, id: \.self) { podcast in

                                SearchResultCell(episode: nil, podcast: podcast, searchHistory: searchHistory)
                            }
                        } else {
                            ForEach(searchResults.episodes, id: \.self) { episode in

                                SearchResultCell(episode: episode, podcast: nil, searchHistory: searchHistory)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(showPodcasts ? L10n.discoverAllPodcasts : L10n.discoverAllEpisodes))
        }
        .padding(.bottom, (PlaybackManager.shared.currentEpisode() != nil) ? Constants.Values.miniPlayerOffset : 0)
        .ignoresSafeArea(.keyboard)
    }
}

struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        InlineResultsView(searchResults: SearchResultsModel(), searchHistory: nil)
    }
}
