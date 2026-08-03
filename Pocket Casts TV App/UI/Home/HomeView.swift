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
            model.refresh()
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
                        DiscoverHomeView(model: tabRouter.discoverHomeSignedInViewModel)
                            .environment(self.model)
                    } else {
                        DiscoverHomeView(model: tabRouter.discoverHomeSignedOutViewModel)
                            .environment(self.model)
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
    }
}

#Preview {
    HomeView(model: HomeViewModel())
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
