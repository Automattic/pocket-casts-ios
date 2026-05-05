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

    private static let allPodcasts = MockData.makePodcasts()
    private static let allPlaylists = MockData.makePlaylists()

    var podcasts: [MockPodcast] = allPodcasts
    var currentPlaying: MockEpisode? = allPlaylists.first?.episodes.first
    var upNext: [MockEpisode] = Array(allPlaylists.flatMap(\.episodes).prefix(3))
    var recentlyPlayed: [MockPodcast] = Array(allPodcasts.shuffled().prefix(10))
    var newReleases: [MockEpisode] = allPodcasts.prefix(8).compactMap(\.episodes.first)

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
