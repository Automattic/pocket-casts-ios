import SwiftUI
import Combine

@Observable
class PodcastDetailViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    let podcast: MockPodcast

    init(podcast: MockPodcast) {
        self.podcast = podcast
    }

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

    func follow() {

    }
}

struct PodcastDetailView: View {

    let model: PodcastDetailViewModel

    enum Layout {
        static let podcastImageSize = CGFloat(418)
        static let episodeImageSize = CGFloat(124)
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .ready:
                podcastView
            }
        }
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var podcastView: some View {
        HStack(alignment: .top) {
            podcastInfo
            VStack {
                episodeList
            }
        }
        .toolbar(.visible, for: .tabBar)
    }

    var podcastInfo: some View {
        VStack(alignment: .leading, spacing: 40) {
            Image(model.podcast.image)
                .resizable()
                .frame(width: Layout.podcastImageSize, height: Layout.podcastImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 8) {
                Text(model.podcast.author ?? "")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(model.podcast.title)
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                Text(model.podcast.podcastDescription ?? "")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            HStack(spacing: 8) {
                Button() {
                    model.follow()
                } label: {
                    Text(L10n.tvPodcastDetailFollowTitle)
                        .font(.caption2)
                }
                Button() {
                    model.follow()
                } label: {
                    Text(L10n.tvPodcastDetailMoreInfoTitle)
                        .font(.caption2)
                }
            }
        }
    }

    var episodeList: some View {
        ScrollView {
            LazyVStack() {
                ForEach(model.podcast.episodes) { episode in
                    NavigationLink(value: episode) {
                        EpisodeRow(episode: episode)
                    }
                    .buttonStyle(.card)
                }
            }
            .navigationDestination(for: MockEpisode.self) { episode in
                Button(episode.title) {
                    
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    PodcastDetailView(model: PodcastDetailViewModel(podcast: MockData.makePodcasts().first!))
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
