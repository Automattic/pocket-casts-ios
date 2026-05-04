import SwiftUI
import Combine

@Observable
class UpNextViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var episodes: [MockEpisode] = []

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                episodes = MockData.makeUpNext()
                state = .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}

struct UpNextView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(MainTabRouter.self) var tabRouter: MainTabRouter

    @State private var model = UpNextViewModel()

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                upNextView
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

    var upNextView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text(L10n.tvTabUpNext)
                        .font(.title)
                        .foregroundStyle(Color.textPrimary)
                    upNextListView
                }
            }
        }
    }

    var emptyView: some View {
        EmptyDataView(title: L10n.tvPodcastsEmptyTitle, subtitle: L10n.tvPodcastsEmptySubtitle, actionTitle: L10n.tvPodcastsEmptyActionTitle) {
            tabRouter.selectedTab = .home
        }
    }

    var upNextListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(model.episodes) { episode in
                    NavigationLink(value: episode) {
                        EpisodeRow(episode: episode)
                    }
                    .buttonStyle(.card)
                }
            }
            .navigationDestination(for: MockEpisode.self) { episode in
                VStack {
                    Button {

                    } label: {
                        Text("Episode \(episode.title) details coming soon")
                            .font(.title2)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    UpNextView()
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
