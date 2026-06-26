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
            Text(L10n.tvPodcastsEmptyTitle)
        } description: {
            Text(L10n.tvPodcastsEmptySubtitle)
        } actions: {
            Button(L10n.tvPodcastsEmptyActionTitle) {
                tabRouter.selectedTab = .home
            }
        }
    }

    @State private var path = NavigationPath()

    var homeView: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: HomeSectionLayout.sectionSpacing) {
                    if coordinator.userState.isLoggedIn {
                        nowPlayingRow
                        upNextRow
                        youMightLikeRow
                        videoRow
                        newReleasesRow
                        lovedByListenersOfRow
                        trendingRow
                        BannerRow(type: .discoverMore, focusSection: Section.homeBanner.rawValue) {
                            tabRouter.selectedTab = .search
                        }
                    } else {
                        nowPlayingRow
                        featuredRow
                        videoRow
                        BannerRow(type: .createAccount, focusSection: Section.homeBanner.rawValue) {
                            tabRouter.pendingAuthFlow = .createAccount
                        }
                        trendingRow
                        categoriesRow
                        curatedRow
                        BannerRow(type: .discoverMore, focusSection: Section.homeBanner.rawValue) {
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
            .syncNavigationDetail(path: path, tabRouter: tabRouter)
        }
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    var nowPlayingRow: some View {
        if model.shouldShowNowPlayingRow, let currentPlaying = model.currentPlaying {
            HomeSection(title: L10n.tvHomeKeepListeningTitle, focusSection: Section.homeNowPlaying.rawValue) {
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
            HomeSection(title: L10n.tvTabUpNext, focusSection: Section.homeUpNext.rawValue) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 24) {
                        ForEach(model.upNext) { episode in
                            upNextButton(model: episode)
                                .frame(width: 864)
                                .setFocus(section: Section.homeUpNext.rawValue)
                        }
                    }
                }
                // Otherwise the focused-card drop shadow gets clipped at the
                // scroll-view boundary instead of pooling below the pill.
                .scrollClipDisabled()
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
        .episodeContextMenu(model: model, context: .upNext)
    }

    var newReleasesRow: some View {
        HomeSection(title: L10n.tvHomeNewReleases, focusSection: Section.homeNewReleases.rawValue) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 24) {
                    ForEach(model.newReleases) { episode in
                        EpisodePlayerButton(model: episode)
                            .frame(width: 864)
                            .setFocus(section: Section.homeNewReleases.rawValue)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}

/// Single source of truth for the spacing between Home + Discover sections
/// and between a section's title and its content row.
enum HomeSectionLayout {
    static let titleSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 64
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
        VStack(alignment: .leading, spacing: HomeSectionLayout.titleSpacing) {
            titleView
            content
        }
        .focusSection()
    }

    // Always reserve space for the larger (focused) title so the layout
    // doesn't jump when the title resizes on focus changes. A hidden copy at
    // the largest font sizes the slot; the visible title is overlaid and
    // bottom-aligned so its distance to the content below stays constant.
    private var titleView: some View {
        Text(title)
            .font(.title3)
            .hidden()
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(isFocusedSection ? .title3 : .headline)
                    .foregroundStyle(Color.pcTextPrimary)
            }
    }
}

#Preview {
    HomeView(model: HomeViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
