import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

struct HomeView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @State private var model: HomeViewModel

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
        case homeNewVideoReleases
        case homeBanner
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                homeView
            }
        }
        .animation(.easeInOut, value: model.state)
        .task {
            Analytics.track(.homeShown)
            model.load()
            model.refresh()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    @State private var path = StackPath()

    var homeView: some View {
        NavigationStack(path: $path.navigationPath) {
            Group {
                if coordinator.userState.isLoggedIn {
                    DiscoverAllView(model: tabRouter.discoverHomeSignedInViewModel, source: DiscoverAnalytics.homeSource)
                } else {
                    DiscoverAllView(model: tabRouter.discoverHomeSignedOutViewModel, source: DiscoverAnalytics.homeSource)
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
    }
}

#Preview {
    HomeView(model: HomeViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
