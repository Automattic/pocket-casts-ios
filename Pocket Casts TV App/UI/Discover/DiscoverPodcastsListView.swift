import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

fileprivate enum Layout {
    static let gridSize = CGFloat(250)
}

struct DiscoverPodcastsListView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabViewModel.self) var tabRouter: MainTabViewModel

    @State private var model: DiscoverCategoryModel

    init(category: DiscoverCategory, source: String) {
        _model = State(wrappedValue: DiscoverCategoryModel(category: category, source: source))
    }

    let gridColumns: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                podcastsView
            case .empty:
                emptyView
            case .failed:
                DiscoverRetryView(style: .fullScreen) { await model.retry() }
            }
        }
        .task {
            await model.load()
        }
        .toolbar(.hidden, for: .tabBar)
    }

    var loadingView: some View {
        ProgressView()
    }

    var podcastsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(L10n.mostPopularWithName(model.name))
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
                podcastGrid
            }
        }
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

    var podcastGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 48) {
            ForEach(model.podcasts, id: \.uuid) { podcast in
                NavigationLink(value: podcast) {
                    DiscoverPodcastCell(podcastUuid: podcast.uuid ?? "", isSponsored: model.isSponsored(podcast: podcast))
                }
                .buttonStyle(.card)
                .accessibilityLabel(podcast.title ?? "")
                .simultaneousGesture(TapGesture().onEnded {
                    model.trackPodcastTapped(podcast)
                })
            }
        }
    }
}

#Preview {
    DiscoverPodcastsListView(category: DiscoverCategory(id: 1, name: "A"), source: DiscoverAnalytics.homeSource)
        .environment(AppCoordinator())
        .environment(MainTabViewModel())
}
