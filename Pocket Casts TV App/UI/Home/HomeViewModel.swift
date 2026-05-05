import SwiftUI
import Combine

@Observable
class HomeViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var podcasts: [MockPodcast] = []
    var currentPlaying: MockEpisode?
    var upNext: [MockEpisode] = []
    var recentlyPlayed: [MockPodcast] = []
    var newReleases: [MockEpisode] = []

    func load() {
        //Mock data load
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                podcasts = MockData.makePodcasts()
                currentPlaying = MockData.makePlaylists().first?.episodes.first
                upNext = Array(MockData.makeUpNext().prefix(3))
                recentlyPlayed = Array(podcasts.shuffled().prefix(10))
                newReleases = podcasts.prefix(8).compactMap(\.episodes.first)
                state = .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }
}
