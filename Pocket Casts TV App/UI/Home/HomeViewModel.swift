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

            newReleases = podcasts.prefix(8).compactMap { podcast in
                guard let latest = dataManager.findLatestEpisode(podcast: podcast) else { return nil }
                return EpisodeRowViewModel(
                    episode: latest,
                    podcastUUID: podcast.uuid,
                    podcastTitle: podcast.title,
                    podcastDescription: podcast.podcastDescription
                )
            }

            state = .ready
        }
    }

    private func fetchPodcasts() -> [Podcast] {
        return Array(dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).prefix(20))
    }

    private func rowViewModel(for episode: BaseEpisode) -> EpisodeRowViewModel {
        let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
        return EpisodeRowViewModel(
            episode: episode,
            podcastUUID: podcast?.uuid,
            podcastTitle: podcast?.title,
            podcastDescription: podcast?.podcastDescription
        )
    }
}
