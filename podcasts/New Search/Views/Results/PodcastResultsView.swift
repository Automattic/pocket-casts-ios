import SwiftUI
import PocketCastsServer

struct PodcastResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    var body: some View {
        VStack {
            ThemedDivider()
            ScrollViewIfNeeded {
                LazyVStack {
                    Section {
                        ForEach(searchResults.podcasts, id: \.self) { podcast in

                            SearchPodcastCell(podcast: podcast, searchHistory: nil)
                        }
                    }
                }
            }
            .navigationBarTitle(Text(L10n.discoverAllPodcasts))
        }
    }
}

struct SearchPodcastCell: View {
    @EnvironmentObject var theme: Theme

    let podcast: PodcastSearchResult
    let searchHistory: SearchHistoryModel?

    var body: some View {
        ZStack {
            Button(action: {
                NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
                searchHistory?.add(podcast: podcast)
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ListCellButtonStyle())

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: 48, height: 48)
                        .allowsHitTesting(false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(podcast.title)
                            .font(style: .subheadline, weight: .medium)
                            .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                            .lineLimit(2)
                        Text(podcast.author)
                            .font(style: .caption, weight: .semibold)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .lineLimit(1)
                    }
                    .allowsHitTesting(false)
                }
                .padding(.trailing, 16)
                ThemedDivider()
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
        }
    }
}


struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastResultsView(searchResults: SearchResultsModel())
    }
}
