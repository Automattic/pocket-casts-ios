import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct PodcastsCarouselView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @State private var tabSelection = 0

    private var height: CGFloat? {
        UIDevice.current.isiPad() ? nil : UIScreen.main.bounds.height * 0.3
    }

    var body: some View {
        ScrollView {
            LazyHStack {
                Group {
                    if searchResults.isSearchingForPodcasts && !searchResults.isShowingLocalResultsOnly {
                        ZStack(alignment: .center) {
                            ProgressView()
                                .tint(AppTheme.loadingActivityColor().color)
                        }
                    } else if searchResults.podcasts.count > 0 {
                        if UIDevice.current.isiPad() {
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 0) {
                                    ForEach(searchResults.podcasts, id: \.self) { podcast in
                                            PodcastResultCell(result: podcast)
                                            .padding(10)
                                            .frame(width: UIScreen.main.bounds.width / 4)
                                    }
                                }
                            }
                        } else {
                            ZStack {
                                Action {
                                    // Always reset the carousel when performing a new search
                                    tabSelection = 0
                                }

                                TabView(selection: $tabSelection) {
                                    ForEach(0..<max(1, searchResults.podcasts.count/2), id: \.self) { i in
                                        GeometryReader { geometry in
                                            HStack(spacing: 10) {
                                                PodcastResultCell(result: searchResults.podcasts[(i * 2)])

                                                if let result = searchResults.podcasts[safe: (i * 2) + 1] {
                                                    PodcastResultCell(result: result)
                                                } else {
                                                    Rectangle()
                                                        .opacity(0)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.all, 10)
                                }
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
                .frame(width: UIScreen.main.bounds.width, height: height)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            ThemedDivider()
                .padding(.leading, 16)
        }
        .background(AppTheme.color(for: .primaryUi02, theme: theme))
    }
}

struct PodcastResultCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel

    let result: PodcastFolderSearchResult

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: {
                    result.navigateTo()
                    searchHistory.add(podcast: result)
                    searchAnalyticsHelper.trackResultTapped(result)
                }) {
                    switch result.kind {
                    case .folder:
                        SearchFolderPreviewWrapper(uuid: result.uuid)
                            .aspectRatio(1, contentMode: .fit)
                            .modifier(NormalCoverShadow())
                    case .podcast:
                        PodcastCover(podcastUuid: result.uuid)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                if result.kind == .podcast {
                    RoundedSubscribeButtonView(podcastUuid: result.uuid)
                }
            }

            Button(action: {
                result.navigateTo()
                searchHistory.add(podcast: result)
                searchAnalyticsHelper.trackResultTapped(result)
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
        switch kind {
        case .folder:
            NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: DataManager.sharedManager.findFolder(uuid: uuid) as Any])
        case .podcast:
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: self])
        }
    }
}
