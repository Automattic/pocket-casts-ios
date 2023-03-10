import SwiftUI
import PocketCastsServer

struct PodcastResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    let searchHistory: SearchHistoryModel?

    var body: some View {
        VStack {
            ThemedDivider()
            ScrollViewIfNeeded {
                LazyVStack {
                    Section {
                        ForEach(searchResults.podcasts, id: \.self) { podcast in

                            SearchEpisodeCell(episode: nil, podcast: podcast, searchHistory: searchHistory)
                        }
                    }
                }
            }
            .navigationBarTitle(Text(L10n.discoverAllPodcasts))
        }
    }
}

struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastResultsView(searchResults: SearchResultsModel(), searchHistory: nil)
    }
}
