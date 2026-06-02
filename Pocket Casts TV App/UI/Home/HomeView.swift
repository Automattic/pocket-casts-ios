import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct HomeView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = HomeViewModel()

    @State private var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let gridSize = CGFloat(250)
        static let sectionSpacing = CGFloat(80)
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
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvPodcastsEmptyTitle, subtitle: L10n.tvPodcastsEmptySubtitle, actionTitle: L10n.tvPodcastsEmptyActionTitle) {
            tabRouter.selectedTab = .home
        }
    }

    var homeView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    if coordinator.userState.isLoggedIn {
                        nowPlayingRow
                        upNextRow
                        youMightLikeRow
                        videoRow
                        newReleasesRow
                        lovedByListenersOfRow
                        trendingRow
                        BannerRow(type: .discoverMore, focusSection: Section.homeBanner) {
                            tabRouter.selectedTab = .search
                        }
                    } else {
                        featuredRow
                        videoRow
                        BannerRow(type: .createAccount, focusSection: Section.homeBanner) {
                            tabRouter.pendingAuthFlow = .createAccount
                        }
                        trendingRow
                        categoriesRow
                        curatedRow
                        BannerRow(type: .discoverMore, focusSection: Section.homeBanner) {
                            tabRouter.selectedTab = .search
                        }
                    }
                }
            }
            .navigationDestination(for: DiscoverPodcast.self) { podcast in
                if let uuid = podcast.uuid {
                    PodcastDetailView(model: PodcastDetailViewModel(podcastUuid: uuid))
                }
            }
            .navigationDestination(for: DiscoverCategory.self) { discoverCategory in
                DiscoverPodcastsListView(category: discoverCategory)
            }
        }
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    var nowPlayingRow: some View {
        if let currentPlaying = model.currentPlaying {
            HomeSection(title: L10n.tvHomeKeepListeningTitle, focusSection: Section.homeNowPlaying) {
                NowPlayingRow(model: currentPlaying) {
                    showNowPlayingPlayer = true
                }
                .frame(width: 1242, alignment: .leading)
                .setFocus(section: Section.homeNowPlaying)
            }
        } else {
            EmptyView()
        }
    }

    var youMightLikeRow: some View {
        HomeSection(title: L10n.tvHomeRecommendedForYouTitle, focusSection: DiscoverType.recommendationsUser) {
            DiscoverPodcastRow(type: .recommendationsUser)
        }
    }

    @State private var sectionPodcast: String?

    var lovedByListenersOfRow: some View {
        HomeSection(title: L10n.tvHomeRecommendUserPodcastSectionTitle(sectionPodcast ?? ""), focusSection: DiscoverType.recommendationsSocial) {
            DiscoverPodcastRow(type: .recommendationsSocial) { title in
                sectionPodcast = title
            }
        }
    }

    var trendingRow: some View {
        HomeSection(title: L10n.tvHomeTrendingSectionTitle, focusSection: DiscoverType.trending) {
            DiscoverPodcastRow(type: .trending)
        }
    }

    var featuredRow: some View {
        HomeSection(title: L10n.tvHomeFeaturedSectionTitle, focusSection: DiscoverType.featured) {
            DiscoverFeaturedPodcastsRow(type: .featured)
        }
    }

    var videoRow: some View {
        HomeSection(title: "Made for TV", focusSection: DiscoverType.video) {
            DiscoverVideoEpisodesRow(type: .video)
        }
    }

    @State private var curatedTitle: String?
    var curatedRow: some View {
        HomeSection(title: curatedTitle ?? L10n.loading, focusSection: DiscoverType.curatedList) {
            DiscoverPodcastRow(type: .curatedList) { title in
                curatedTitle = title
            }
        }
    }

    var categoriesRow: some View {
        HomeSection(title: L10n.tvHomeBrowseCategoriesSectionTitle, focusSection: DiscoverType.categories) {
            DiscoverCategoriesRow()
        }
    }

    @ViewBuilder
    var upNextRow: some View {
        if model.upNext.count > 1 {
            HomeSection(title: L10n.tvTabUpNext, focusSection: Section.homeUpNext) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 24) {
                        ForEach(model.upNext) { episode in
                            upNextButton(model: episode)
                                .frame(width: 864)
                                .setFocus(section: Section.homeUpNext)
                        }
                    }
                }
            }
        }
    }

    func upNextButton(model: EpisodeRowViewModel) -> some View {
        Button {
            model.play()
            showNowPlayingPlayer = true
        } label: {
            EpisodeRow(model: model, isActive: false)
        }
        .buttonStyle(EpisodeRowButtonStyle())
    }

    var newReleasesRow: some View {
        HomeSection(title: L10n.tvHomeNewReleases, focusSection: Section.homeNewReleases) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 24) {
                    ForEach(model.newReleases) { episode in
                        EpisodePlayerButton(model: episode)
                            .frame(width: 864)
                            .setFocus(section: Section.homeNewReleases)
                    }
                }
            }
        }
    }
}

struct HomeSection<Content: View>: View {
    private let title: String
    private let focusSection: AnyHashable
    private let content: Content

    @Environment(FocusStore.self) var focusStore

    init(title: String, focusSection: AnyHashable, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.focusSection = focusSection
    }

    private var isFocusedSection: Bool {
        focusStore.focusedID == focusSection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(title)
                .font(isFocusedSection ? .title2 : .headline)
                .foregroundStyle(Color.pcTextPrimary)
            content
        }
        .focusSection()
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
