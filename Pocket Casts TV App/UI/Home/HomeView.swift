import SwiftUI
import PocketCastsDataModel

struct HomeView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = HomeViewModel()

    @State private var showNowPlayingPlayer: Bool = false

    enum Layout {
        static let gridSize = CGFloat(250)
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
                VStack(alignment: .leading, spacing: 80) {
                    nowPlayingRow
                    upNextRow
                    youMightLikeRow
                    newReleasesRow
                    lovedByListenersOfRow
                    trendingRow
                }
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
            VStack(alignment: .leading, spacing: 32) {
                Text(L10n.tvHomeKeepListeningTitle)
                    .font(.title2)
                    .foregroundStyle(Color.textPrimary)
                NowPlayingRow(model: currentPlaying) {
                    showNowPlayingPlayer = true
                }
                .frame(width: 1242, alignment: .leading)
            }
            .focusSection()
        } else {
            EmptyView()
        }
    }

    var youMightLikeRow: some View {
        HomeSection(title: L10n.tvHomeRecommendedForYouTitle) {
            DiscoverPodcastRow(type: .recommendationsUser)
        }
        .focusSection()
    }

    @State private var sectionPodcast: String?

    var lovedByListenersOfRow: some View {
        HomeSection(title: L10n.tvHomeRecommendUserPodcastSectionTitle(sectionPodcast ?? "")) {
            DiscoverPodcastRow(type: .recommendationsSocial) { title in
                sectionPodcast = title
            }
        }
    }

    var trendingRow: some View {
        HomeSection(title: L10n.tvHomeTrendingSectionTitle) {
            DiscoverPodcastRow(type: .trending)
        }
    }

    @ViewBuilder
    var upNextRow: some View {
        if model.upNext.count > 1 {
            HomeSection(title: L10n.tvTabUpNext) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 24) {
                        ForEach(model.upNext) { episode in
                            upNextButton(model: episode)
                                .frame(width: 864)
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
        HomeSection(title: L10n.tvHomeNewReleases) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 24) {
                    ForEach(model.newReleases) { episode in
                        EpisodePlayerButton(model: episode)
                            .frame(width: 864)
                    }
                }
            }
        }
    }
}

struct HomeSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            content
        }
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
