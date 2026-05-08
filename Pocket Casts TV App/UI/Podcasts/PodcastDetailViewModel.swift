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

    let podcast: Podcast
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

    var isFollowing: Bool = false

    func follow() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isFollowing.toggle()
        }
    }
}
