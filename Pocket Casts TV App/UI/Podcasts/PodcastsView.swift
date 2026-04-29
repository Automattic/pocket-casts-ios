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
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                state = .empty
            }
    }
}

struct PodcastsView: View {
    @Environment(AppCoordinator.self) var coordinator

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
        VStack(alignment: .leading, spacing: 40) {
            Text(L10n.tvTabPodcasts)
                .font(.title)
                .foregroundStyle(Color.textPrimary)
            ScrollView {
                podcastGrid
            }
            .contentMargins(.vertical, 60, for: .scrollContent)
        }
    }

    var emptyView: some View {
        EmptyView(title: L10n.tvPodcastsEmptyTitle, subtitle: L10n.tvPodcastsEmptySubtitle, actionTitle: L10n.tvPodcastsEmptyActionTitle) {

        }
    }

    private let items: [GridItem] = (0..<6).map { _ in
        GridItem(.fixed(Layout.gridSize), spacing: 48)
    }

    var podcastGrid: some View {
        LazyVGrid(columns: items, spacing: 48, content: {
            ForEach(model.podcasts) { podcast in
                Button() {

                } label: {
                    Image(podcast.image)
                        .resizable()
                        .frame(width: Layout.gridSize, height: Layout.gridSize)
                }.buttonStyle(.card)
            }
        })
    }
}

#Preview {
    PodcastsView()
        .environment(AppCoordinator())
}
