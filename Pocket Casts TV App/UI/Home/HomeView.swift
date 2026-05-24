import SwiftUI
import PocketCastsDataModel

struct HomeView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = HomeViewModel()

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
                            NowPlayingRow(model: currentPlaying)
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
    }

    @Namespace private var podcastGridNamespace

    var discoverCollection: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0, content: {
                ForEach(model.podcasts) { podcast in
                    NavigationLink(value: podcast) {
                        PodcastImage(uuid: podcast.uuid, size: .page)
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                    }
                    .buttonStyle(.card)
                    .padding(24)
                    .prefersDefaultFocus(model.podcasts.first?.uuid == podcast.uuid, in: podcastGridNamespace)
                }
            })
            .focusScope(podcastGridNamespace)
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
            }
        }
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
                        ForEach(model.upNext.dropFirst()) { episode in
                            EpisodePlayerButton(model: episode)
                                .frame(width: 864)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
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
