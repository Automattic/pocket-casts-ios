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
    var currentPlaying: EpisodeRowViewModel?
    var upNext: [EpisodeRowViewModel] = []
    var recentlyPlayed: [Podcast] = []
    var newReleases: [EpisodeRowViewModel] = []

    func load() {
        Task {
            podcasts = fetchPodcasts()
            recentlyPlayed = Array(podcasts.shuffled().prefix(10))

            let upNextEpisodes = dataManager.allUpNextEpisodes()
            upNext = Array(upNextEpisodes.prefix(3)).map { episode in
                rowViewModel(for: episode)
            }
            currentPlaying = upNext.first

            var newEpisodes = [EpisodeRowViewModel]()
            for podcast in podcasts.prefix(8) {
                guard let latest: Episode = dataManager.findLatestEpisode(podcast: podcast) else {
                    continue
                }
                let result = EpisodeRowViewModel(episode: latest, podcast: podcast)
                newEpisodes.append(result)
            }
            newReleases = newEpisodes

            state = .ready
        }
    }

    private func fetchPodcasts() -> [Podcast] {
        return Array(dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).prefix(20))
    }

    private func rowViewModel(for episode: BaseEpisode) -> EpisodeRowViewModel {
        let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
        return EpisodeRowViewModel(episode: episode, podcast: podcast)
    }
}
