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

    var isFollowing: Bool = false

    func follow() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isFollowing.toggle()
        }
    }
}
