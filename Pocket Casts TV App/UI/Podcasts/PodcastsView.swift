import SwiftUI
import PocketCastsDataModel

fileprivate enum Layout {
    static let gridSize = CGFloat(250)
}

struct PodcastsView<ViewModel: PodcastsViewModelInterface>: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model: ViewModel

    init(model: ViewModel = PodcastsViewModel()) {
        self.model = model
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
    }

    var loadingView: some View {
        ProgressView()
    }

    var podcastsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text(L10n.tvTabPodcasts)
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)
                    podcastGrid
                }
            }
        }
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvPodcastsEmptyTitle, subtitle: L10n.tvPodcastsEmptySubtitle, actionTitle: L10n.tvPodcastsEmptyActionTitle) {
            tabRouter.selectedTab = .home
        }
    }

    @Namespace private var podcastGridNamespace

    var podcastGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 48) {
            ForEach(model.items) { item in
                switch item {
                case .podcast(let podcast):
                    NavigationLink(value: podcast) {
                        PodcastImageViewWrapper(podcastUUID: podcast.uuid, size: .page)
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                    }
                    .buttonStyle(.card)
                    //.prefersDefaultFocus(item.id == items.first?.id, in: podcastGridNamespace)
                case .folder(let folder):
                    NavigationLink(value: folder) {
                        FolderCardView(folder: folder)
                    }
                    .buttonStyle(.card)
                }
            }
        }
        .focusScope(podcastGridNamespace)
        .navigationDestination(for: MockPodcast.self) { podcast in
            PodcastDetailView(model: PodcastDetailViewModel(podcast: podcast))
        }
        .navigationDestination(for: MockFolder.self) { folder in
            FolderDetailView(folder: folder)
        }
    }
}

#Preview {
    PodcastsView(model: PodcastsViewModelMock())
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
