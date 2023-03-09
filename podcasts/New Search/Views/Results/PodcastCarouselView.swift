import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct PodcastsCarouselView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    @State private var tabSelection = 0

    var body: some View {
        ScrollView {
            LazyHStack {
                Group {
                    if searchResults.isSearchingForPodcasts {
                        ZStack(alignment: .center) {
                            ProgressView()
                        }
                    } else if searchResults.podcasts.count > 0 {
                        ZStack {
                            Action {
                                // Always reset the carousel when performing a new search
                                tabSelection = 0
                            }

                            TabView(selection: $tabSelection) {
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
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text(L10n.discoverNoPodcastsFound)
                                .font(style: .subheadline, weight: .medium)

                            Text(L10n.discoverNoPodcastsFoundMsg)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.all, 10)
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.3)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            ThemedDivider()
                .padding(.leading, 16)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
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
                .padding([.trailing, .bottom], 6)
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
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                }
            }
        }
    }
}
