import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

fileprivate enum Layout {
    static let gridSize = CGFloat(250)
}

struct DiscoverPodcastsListView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model: DiscoverCategoryModel

    init(category: DiscoverCategory) {
        _model = State(wrappedValue: DiscoverCategoryModel(category: category))
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
            }
        }
        .task {
            await model.load()
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear { tabRouter.isShowingDetail = true }
        .onDisappear { tabRouter.isShowingDetail = false }
    }

    var loadingView: some View {
        ProgressView()
    }

    var podcastsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(model.name)
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
                podcastGrid
            }
        }
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

    var podcastGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 48) {
            ForEach(model.categoryDetails?.podcasts ?? [], id: \.uuid) { podcast in
                NavigationLink(value: podcast) {
                    PodcastImage(uuid: podcast.uuid ?? "", size: .page)
                        .frame(width: Layout.gridSize, height: Layout.gridSize)
                }
                .buttonStyle(.card)
            }
        }
    }
}

#Preview {
    DiscoverPodcastsListView(category: DiscoverCategory(id: 1, name: "A"))
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
