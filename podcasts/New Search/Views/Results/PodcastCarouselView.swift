import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct PodcastsCarouselView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    var searchHistory: SearchHistoryModel?

    @State private var tabSelection = 0

    var body: some View {
        ScrollView {
            LazyHStack {
                Group {
                    if searchResults.isSearchingForPodcasts && !searchResults.isShowingLocalResultsOnly {
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
                                ForEach(0..<max(1, searchResults.podcasts.count/2), id: \.self) { i in
                                    GeometryReader { geometry in
                                        HStack(spacing: 10) {
                                            PodcastResultCell(result: searchResults.podcasts[(i * 2)], searchHistory: searchHistory)

                                            if let result = searchResults.podcasts[safe: (i * 2) + 1] {
                                                PodcastResultCell(result: result, searchHistory: searchHistory)
                                            }
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

    let result: PodcastFolderSearchResult
    let searchHistory: SearchHistoryModel?

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: {
                    result.navigateTo()
                    searchHistory?.add(podcast: result)
                }) {
                    if result.kind == .folder {
                        SearchFolderPreviewWrapper(uuid: result.uuid)
                            .modifier(NormalCoverShadow())
                    } else {
                        PodcastCover(podcastUuid: result.uuid)
                    }
                }
                if result.kind == .podcast {
                    RoundedSubscribeButtonView(podcastUuid: result.uuid)
                }
            }

            Button(action: {
                result.navigateTo()
                searchHistory?.add(podcast: result)
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .lineLimit(1)
                        .font(style: .subheadline, weight: .medium)
                    Text(result.author)
                        .lineLimit(1)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                }
            }
        }
    }
}

extension PodcastFolderSearchResult {
    func navigateTo() {
        if kind == .folder {
            NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: DataManager.sharedManager.findFolder(uuid: uuid) as Any])
        } else {
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: self])
        }
    }
}
