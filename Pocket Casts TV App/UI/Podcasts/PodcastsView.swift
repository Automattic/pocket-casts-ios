import SwiftUI

private enum GridCellItem {
    case podcast(MockPodcast)
    case folder(MockFolder)

    var id: String {
        switch self {
        case .podcast(let p): return p.id
        case .folder(let f): return f.id
        }
    }
}

struct PodcastsView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = PodcastsViewModel()

    enum Layout {
        static let gridSize = CGFloat(250)
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
            model.load()
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

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    @Namespace private var podcastGridNamespace

    private var gridItems: [GridCellItem] {
        var result: [GridCellItem] = model.podcasts.map { .podcast($0) }
        for (offset, folder) in model.folders.enumerated() {
            let insertionIndex = min(2 + offset, result.count)
            result.insert(.folder(folder), at: insertionIndex)
        }
        return result
    }

    var podcastGrid: some View {
        let items = gridItems
        return LazyVGrid(columns: self.items, spacing: 48, content: {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                switch item {
                case .podcast(let podcast):
                    NavigationLink(value: podcast) {
                        Image(podcast.image)
                            .resizable()
                            .frame(width: Layout.gridSize, height: Layout.gridSize)
                    }
                    .buttonStyle(.card)
                    .prefersDefaultFocus(index == 0, in: podcastGridNamespace)
                case .folder(let folder):
                    NavigationLink(value: folder) {
                        FolderCardView(folder: folder)
                    }
                    .buttonStyle(.card)
                }
            }
        })
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
    PodcastsView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
