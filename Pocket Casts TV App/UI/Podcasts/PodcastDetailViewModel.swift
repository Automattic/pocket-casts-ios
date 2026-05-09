import SwiftUI
import Combine
import PocketCastsDataModel

@Observable
class PodcastDetailViewModel {

    private let dataManager: DataManager

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    var podcast: Podcast
    var episodes: [EpisodeRowViewModel] = []
    var recommendedEpisode: EpisodeRowViewModel?

    init(podcast: Podcast, dataManager: DataManager = DataManager.sharedManager) {
        self.podcast = podcast
        self.dataManager = dataManager
    }

    func load() {
        Task {
            let fetched = fetchEpisodes()
            let podcastTitle = podcast.title
            let podcastDescription = podcast.podcastDescription

            episodes = fetched.map {
                EpisodeRowViewModel(
                    episode: $0,
                    podcastUUID: podcast.uuid,
                    podcastTitle: podcastTitle,
                    podcastDescription: podcastDescription
                )
            }
            recommendedEpisode = episodes.first
            state = .ready
        }
    }

    private func fetchEpisodes() -> [Episode] {
        dataManager.allEpisodesForPodcast(id: podcast.id)
    }

    var isFollowing: Bool {
        podcast.isSubscribed()
    }

    func follow() {
        podcast.subscribed = 0
    }
}
