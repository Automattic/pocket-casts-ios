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
                    }
                    upNextRow
                    VStack(alignment: .leading, spacing: 24) {
                        Text(L10n.tvHomeRecommendedForYouTitle)
                            .font(.title3)
                            .foregroundStyle(Color.textPrimary)
                        discoverCollection
                    }
                    VStack(alignment: .leading, spacing: 24) {
                        Text(L10n.tvHomeRecentlyPlayed)
                            .font(.title3)
                            .foregroundStyle(Color.textPrimary)
                        recentlyPlayedRow
                    }
                    Text(L10n.tvHomeNewReleases)
                        .font(.title3)
                        .foregroundStyle(Color.textPrimary)
                    newReleasesRow
                }
            }
        }
        .fullScreenCover(isPresented: $showNowPlayingPlayer) {
            NowPlayingView()
                .ignoresSafeArea()
        }
    }

    @Namespace private var podcastGridNamespace

    var discoverCollection: some View {
        TrendingPodcastRow()
    }

    @ViewBuilder
    var upNextRow: some View {
        if model.upNext.count > 1 {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.tvTabUpNext)
                    .font(.title3)
                    .foregroundStyle(Color.textPrimary)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 24) {
                        ForEach(model.upNext) { episode in
                            upNextButton(model: episode)
                                .frame(width: 864)
                        }
                    }
                    .padding(.horizontal, 24)
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

    var recentlyPlayedRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(model.recentlyPlayed) { podcast in
                    NavigationLink(value: podcast) {
                        PodcastImage(uuid: podcast.uuid, size: .page)
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                    }
                    .buttonStyle(.card)
                    .padding(24)
                }
            }
        }
    }

    var newReleasesRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 24) {
                ForEach(model.newReleases) { episode in
                    EpisodePlayerButton(model: episode)
                        .frame(width: 864)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
