import SwiftUI
import Combine
import PocketCastsDataModel

@Observable
class PodcastDetailViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    var podcast: Podcast
    let episodes: [MockEpisode]

    let recommendedEpisode: MockEpisode?

    init(podcast: Podcast) {
        self.podcast = podcast
        self.episodes = MockData.makePodcasts().first?.episodes ?? []
        self.recommendedEpisode = MockData.makePodcasts().first?.episodes.randomElement()
    }

    func load() {
        state = .ready
    }

    var isFollowing: Bool {
        podcast.isSubscribed()
    }

    func follow() {
        podcast.subscribed = 0
    }
}
