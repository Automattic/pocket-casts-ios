import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct HomeView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @State private var model: HomeViewModel

    @State private var showNowPlayingPlayer: Bool = false

    init(model: HomeViewModel) {
        _model = State(wrappedValue: model)
    }

    enum Layout {
        static let gridSize = CGFloat(250)
    }

    enum Section: String {
        case homeNowPlaying
        case homeUpNext
        case homeNewReleases
        case homeBanner
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                homeView
            case .empty:
                emptyView
            }
        }
        .animation(.easeInOut, value: model.state)
        .task {
            Analytics.track(.homeShown)
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var emptyView: some View {
        ContentUnavailableView {
            Text(L10n.tvPodcastsEmptyTitleNew)
        } description: {
            Text(L10n.tvPodcastsEmptySubtitle)
        } actions: {
            Button(L10n.tvPodcastsEmptyActionTitle) {
                tabRouter.selectedTab = .home
            }
        }
    }

    @State private var path = StackPath()

    var homeView: some View {
        NavigationStack(path: $path.navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: RowSectionLayout.sectionSpacing) {
                    if coordinator.userState.isLoggedIn {
                        nowPlayingRow
                        upNextRow
                        videoRow
                        youMightLikeRow
                        newReleasesRow
                        lovedByListenersOfRow
                        trendingRow
                        BannerRow(type: .discoverMore, focusSection: Section.homeBanner.rawValue) {
                            Analytics.track(.bannerRowTapped, properties: ["type": "discover_more"])
                            tabRouter.selectedTab = .search
                        }
                    } else {
                        nowPlayingRow
                        featuredRow
                        videoRow
                        BannerRow(type: .createAccount, focusSection: Section.homeBanner.rawValue) {
                            Analytics.track(.bannerRowTapped, properties: ["type": "create_account"])
                            tabRouter.pendingAuthFlow = .createAccount
                        }
                        trendingRow
                        categoriesRow
                        curatedRow
                        BannerRow(type: .discoverMore, focusSection: Section.homeBanner.rawValue) {
                            Analytics.track(.bannerRowTapped, properties: ["type": "discover_more"])
                            tabRouter.selectedTab = .search
                        }
                    }
                }
            }
            .navigationDestination(for: DiscoverPodcast.self) { podcast in
                if let uuid = podcast.uuid {
                    PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid, isDiscover: true))
                }
            }
            .navigationDestination(for: DiscoverCategory.self) { discoverCategory in
                DiscoverPodcastsListView(category: discoverCategory, source: DiscoverAnalytics.homeSource)
            }
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: podcast.uuid))
            }
            .syncNavigationDetail(path: path.navigationPath, tabRouter: tabRouter)
        }
        .environment(path)
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    var nowPlayingRow: some View {
        if model.shouldShowNowPlayingRow, let currentPlaying = model.currentPlaying {
            RowSection(title: L10n.tvHomeKeepListeningTitle, focusSection: Section.homeNowPlaying.rawValue) {
                NowPlayingRow(model: currentPlaying) {
                    showNowPlayingPlayer = true
                }
                .frame(width: 1242, alignment: .leading)
                .setFocus(section: Section.homeNowPlaying.rawValue)
            }
        } else {
            EmptyView()
        }
    }

    var youMightLikeRow: some View {
        DiscoverPodcastRow(type: .recommendationsUser, source: DiscoverAnalytics.homeSource)
    }

    var lovedByListenersOfRow: some View {
        DiscoverPodcastRow(type: .recommendationsSocial, source: DiscoverAnalytics.homeSource)
    }

    var trendingRow: some View {
        DiscoverPodcastRow(type: .trending, source: DiscoverAnalytics.homeSource)
    }

    var featuredRow: some View {
        DiscoverFeaturedPodcastsRow(type: .featured, source: DiscoverAnalytics.homeSource)
    }

    var videoRow: some View {
        DiscoverVideoEpisodesRow(type: .video, source: DiscoverAnalytics.homeSource)
    }

    var curatedRow: some View {
        DiscoverPodcastRow(type: .curatedList, source: DiscoverAnalytics.homeSource)
    }

    var categoriesRow: some View {
        DiscoverCategoriesRow(popularOnly: true, source: DiscoverAnalytics.homeSource)
    }

    @ViewBuilder
    var upNextRow: some View {
        if model.upNext.count > 1 {
            EpisodesHorizontalList(title: L10n.tvTabUpNext, focusSection: Section.homeUpNext.rawValue, episodes: model.upNext, episodeContext: .upNext) {
                showNowPlayingPlayer = true
            }
        }
    }

    @ViewBuilder
    var newReleasesRow: some View {
        if !model.newReleases.isEmpty {
            EpisodesHorizontalList(title: L10n.tvHomeNewReleases, focusSection: Section.homeNewReleases.rawValue, episodes: model.newReleases, episodeContext: .other(showGoToPodcast: true)) {
                showNowPlayingPlayer = true
            }
        }
    }
}

#Preview {
    HomeView(model: HomeViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
