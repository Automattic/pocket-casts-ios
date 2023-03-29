import SwiftUI
import PocketCastsServer

struct SearchResultsListView: View {
    enum DisplayMode: String, AnalyticsDescribable {
        case podcasts
        case episodes

        var analyticsDescription: String {
            rawValue
        }
    }

    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    var displayMode: DisplayMode

    var body: some View {
        VStack(spacing: 0) {
            ThemedDivider()
            ScrollView {
                LazyVStack(spacing: 0) {
                    Section {
                        switch displayMode {
                        case .podcasts:
                            ForEach(searchResults.podcasts, id: \.self) { podcast in

                                SearchResultCell(episode: nil, podcast: podcast)
                            }

                        case .episodes:
                            ForEach(searchResults.episodes, id: \.self) { episode in

                                SearchResultCell(episode: episode, podcast: nil)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(displayMode == .podcasts ? L10n.discoverAllPodcasts : L10n.discoverAllEpisodes))
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            searchAnalyticsHelper.trackListShown(displayMode)
        }
        .modifier(MiniPlayerPadding())
        .applyDefaultThemeOptions()
    }
}

struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsListView(displayMode: .podcasts)
    }
}
