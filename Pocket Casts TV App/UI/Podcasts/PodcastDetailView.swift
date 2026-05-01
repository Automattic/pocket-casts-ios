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
    let recommendedEpisode: MockEpisode?

    init(podcast: MockPodcast) {
        self.podcast = podcast
        self.recommendedEpisode = podcast.episodes.randomElement()
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
        static let infoPanelWidth = CGFloat(568)
        static let gutter = CGFloat(24)
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
        .toolbar(.hidden, for: .tabBar)
        .task {
            model.load()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    var podcastView: some View {
        HStack(alignment: .top, spacing: Layout.gutter) {
            podcastInfo
                .frame(width: Layout.infoPanelWidth)
            episodeContent
        }
    }

    var podcastInfo: some View {
        VStack(alignment: .leading, spacing: 40) {
            Image(model.podcast.image)
                .resizable()
                .frame(width: Layout.podcastImageSize, height: Layout.podcastImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .focusSection()
    }

    @Namespace private var episodeListNamespace

    var episodeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                if let recommended = model.recommendedEpisode {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tvPodcastDetailStartHere)
                                .font(.title3)
                                .foregroundStyle(Color.textPrimary)
                            Text(L10n.tvPodcastDetailStartHereSubtitle)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        EpisodePlayerButton(
                            episode: recommended,
                            podcastTitle: model.podcast.title,
                            podcastDescription: model.podcast.podcastDescription
                        )
                        .prefersDefaultFocus(in: episodeListNamespace)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.tvPodcastDetailAllEpisodes)
                        .font(.title3)
                        .foregroundStyle(Color.textPrimary)
                    LazyVStack {
                        ForEach(model.podcast.episodes) { episode in
                            EpisodePlayerButton(
                                episode: episode,
                                podcastTitle: model.podcast.title,
                                podcastDescription: model.podcast.podcastDescription
                            )
                        }
                    }
                }
            }
            .focusScope(episodeListNamespace)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    PodcastDetailView(model: PodcastDetailViewModel(podcast: MockData.makePodcasts().first!))
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
