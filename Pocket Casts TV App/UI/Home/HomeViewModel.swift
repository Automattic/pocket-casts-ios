import SwiftUI
import Combine
import PocketCastsDataModel

@Observable
class HomeViewModel {

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading

    var podcasts: [Podcast] = []
    var currentPlaying: MockEpisode?
    var upNext: [MockEpisode] = []
    var recentlyPlayed: [Podcast] = []
    var newReleases: [MockEpisode] = []

    func load() {
        Task {
            podcasts = fetchPodcasts()
            currentPlaying = MockData.makePlaylists().first?.episodes.first
            upNext = Array(MockData.makeUpNext().prefix(3))
            recentlyPlayed = Array(podcasts.shuffled().prefix(10))
            newReleases = MockData.makePodcasts().prefix(8).compactMap(\.episodes.first)
            state = .ready
        }
    }

    private func fetchPodcasts() -> [Podcast] {
        return Array(dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).prefix(20))
    }
}
