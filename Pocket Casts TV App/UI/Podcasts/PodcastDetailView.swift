import SwiftUI
import Combine
import PocketCastsUtils

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

    func displayDate(for date: Date) -> String {
        let episodeDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase
        return episodeDate
    }

    func displayDuration(for time: Double) -> String {
        let time = TimeFormatter.shared.multipleUnitFormattedShortTime(time: time)
        return time
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
        HStack {
            podcastInfo
            episodeList
        }
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
            HStack {
                Button() {
                    model.follow()
                } label: {
                    Text("Follow")
                        .font(.caption2)
                }
                Button() {
                    model.follow()
                } label: {
                    Text("More Info")
                        .font(.caption2)
                }
            }
        }
    }

    var episodeList: some View {
        List() {
            ForEach(model.podcast.episodes) { episode in
                Button() {

                } label: {
                    HStack {
                        Image(model.podcast.image)
                            .resizable()
                            .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                        VStack(alignment: .leading) {
                            Text(model.displayDate(for: episode.publishedDate))
                            Text(episode.title)
                            Text(model.displayDuration(for: episode.duration))
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.card)
            }
        }
    }
}

#Preview {
    PodcastDetailView(model: PodcastDetailViewModel(podcast: MockData.makePodcasts().first!))
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
