import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct PodcastsCarouselView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var searchHistory: SearchHistoryModel

    @State private var tabSelection = 0

    private var podcastCellWidth: CGFloat {
        UIDevice.current.isiPad() ? UIScreen.main.bounds.width / 4.3 : UIScreen.main.bounds.width / 2.1
    }

    var body: some View {
        Group {
            if searchResults.isSearchingForPodcasts && !searchResults.isShowingLocalResultsOnly {
                ZStack(alignment: .center) {
                    ProgressView()
                        .tint(AppTheme.loadingActivityColor().color)

                    ScrollView(.horizontal) {
                        if let podcast = PodcastFolderSearchResult(from: Podcast.previewPodcast()) {
                            LazyHStack(spacing: 0) {
                                PodcastResultCell(result: podcast)
                                    .padding(10)
                                    .frame(width: podcastCellWidth)
                                    .opacity(0)
                            }
                        }
                    }
                }
            } else if searchResults.podcasts.count > 0 {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(searchResults.podcasts, id: \.self) { podcast in
                                PodcastResultCell(result: podcast)
                                .padding(10)
                                .frame(width: podcastCellWidth)
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

            ThemedDivider()
                .padding(.leading, 16)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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

                }) {
                    Group {
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
                    .gesture(TapGesture().onEnded { _ in
                        // This action is here instead of button action
                        // to avoid conflicts with the dismiss keyboard code
                        result.navigateTo()
                        searchHistory.add(podcast: result)
                        searchAnalyticsHelper.trackResultTapped(result)
                    })
                }

                if result.kind == .podcast {
                    RoundedSubscribeButtonView(podcastUuid: result.uuid)
                }
            }

            Button(action: { }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .lineLimit(1)
                        .font(style: .subheadline, weight: .medium)
                    Text(result.author)
                        .lineLimit(1)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                }
                .gesture(TapGesture().onEnded { _ in
                    // This action is here instead of button action
                    // to avoid conflicts with the dismiss keyboard code
                    result.navigateTo()
                    searchHistory.add(podcast: result)
                    searchAnalyticsHelper.trackResultTapped(result)
                })
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
