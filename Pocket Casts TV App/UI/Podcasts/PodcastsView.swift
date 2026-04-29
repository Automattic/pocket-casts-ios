import SwiftUI
import Combine

@Observable
class PodcastsViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var podcasts: [MockPodcast] = MockData.makePodcasts()

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
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(L10n.tvTabPodcasts)
                    .font(.title)
                    .foregroundStyle(Color.textPrimary)
                podcastGrid
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

    var podcastGrid: some View {
        LazyVGrid(columns: items, spacing: 48, content: {
            ForEach(model.podcasts) { podcast in
                Button() {

                } label: {
                    Image(podcast.image)
                        .resizable()
                        .frame(width: Layout.gridSize, height: Layout.gridSize)
                }
                .buttonStyle(.card)
                .prefersDefaultFocus(model.podcasts.first?.id == podcast.id, in: podcastGridNamespace)
            }
        })
        .focusScope(podcastGridNamespace)
    }
}

#Preview {
    PodcastsView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
