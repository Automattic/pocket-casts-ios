import SwiftUI
import Combine

@Observable
class HomeViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var podcasts: [MockPodcast] = MockData.makePodcasts()
    var currentPlaying: MockEpisode? = MockData.makePlaylists().first?.episodes.first
    var upNext: MockEpisode? = MockData.makePlaylists().last?.episodes.first

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                state = .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}

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
                VStack(alignment: .leading, spacing: 40) {
                    Text(L10n.tvHomeKeepListeningTitle)
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)
                    if let currentPlaying = model.currentPlaying {
                        NavigationLink(value: currentPlaying) {
                            EpisodeRow(episode: currentPlaying)
                        }.buttonStyle(.card)
                    }
                    Text(L10n.tvHomeRecommendedForYouTitle)
                        .font(.title3)
                        .foregroundStyle(Color.textPrimary)
                    discoverCollection
                    Text(L10n.tvTabUpNext)
                        .font(.title3)
                        .foregroundStyle(Color.textPrimary)
                    if let upNext = model.upNext {
                        NavigationLink(value: upNext) {
                            EpisodeRow(episode: upNext)
                        }.buttonStyle(.card)
                    }
                }
                .navigationDestination(for: MockEpisode.self) { episode in
                    Button(episode.title) {

                    }
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
                        Image(podcast.image)
                            .resizable()
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                    }
                    .buttonStyle(.card)
                    .padding(24)
                    .prefersDefaultFocus(model.podcasts.first?.id == podcast.id, in: podcastGridNamespace)
                }
            })
            .focusScope(podcastGridNamespace)
            .navigationDestination(for: MockPodcast.self) { podcast in
                PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
