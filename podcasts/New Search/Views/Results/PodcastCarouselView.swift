import SwiftUI
import PocketCastsDataModel

struct PodcastsCarouselView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResults

    let size: Double = 0.48
    var body: some View {
        ScrollView {
            LazyHStack {
                TabView {
                    ForEach(0..<(searchResults.podcasts.count/2), id: \.self) { i in
                        GeometryReader { geometry in
                            HStack(spacing: 10) {
                                PodcastResultCell(podcast: searchResults.podcasts[(i * 2)])

                                PodcastResultCell(podcast: searchResults.podcasts[(i * 2) + 1])
                            }
                        }
                    }
                    .padding(.all, 10)
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.3)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            ThemeableSeparatorView()
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
        .background(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
    }
}

struct PodcastResultCell: View {
    @EnvironmentObject var theme: Theme

    let podcast: PodcastSearchResult

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: {
                    print("podcast tapped")
                }) {
                    PodcastCover(podcastUuid: podcast.uuid)
                }
                Button(action: {
                    print("subscribe")
                }) {
                    Image("discover_subscribe_dark")
                }
                .background(ThemeColor.veil().color)
                .foregroundColor(ThemeColor.contrast01().color)
                .cornerRadius(30)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 6))
            }

            Button(action: {
                print("podcast tapped")
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(podcast.title)
                        .lineLimit(1)
                        .font(style: .subheadline, weight: .medium)
                    Text(podcast.author)
                        .lineLimit(1)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                }
            }
        }
    }
}
