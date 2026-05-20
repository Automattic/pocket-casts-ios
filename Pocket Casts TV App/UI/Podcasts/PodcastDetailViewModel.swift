import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@Observable
class PodcastDetailViewModel {

    private let dataManager: DataManager
    private let serverPodcastManager: ServerPodcastManager

    enum State: Equatable, Hashable {
        case loading
        case ready
        case failed
    }

    var state: State = .loading

    var podcastUuid: String
    var podcast: Podcast?
    var episodes: [EpisodeRowViewModel] = []
    var recommendedEpisode: EpisodeRowViewModel?

    init(podcast: Podcast, dataManager: DataManager = DataManager.sharedManager, serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared) {
        self.podcastUuid = podcast.uuid
        self.podcast = podcast
        self.dataManager = dataManager
        self.serverPodcastManager = serverPodcastManager
    }

    init(podcastUuid: String, dataManager: DataManager = DataManager.sharedManager, serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared) {
        self.podcastUuid = podcastUuid
        self.dataManager = dataManager
        self.serverPodcastManager = serverPodcastManager
    }

    func load() {
        Task {
            if podcast == nil {
                podcast = await loadPodcast(podcastUuid: podcastUuid)
            }
            if podcast == nil {
                state = .failed
            }
            let episodes = fetchEpisodes()
            let episodesModel = episodes.map {
                EpisodeRowViewModel(episode: $0, podcast: podcast)
            }
            await MainActor.run {
                self.episodes = episodesModel
                recommendedEpisode = episodesModel.first
                state = .ready
            }
        }
    }

    private func loadPodcast(podcastUuid: String) async -> Podcast? {
        await withCheckedContinuation { continuation in
            if let podcast = dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                serverPodcastManager.updatePodcastIfRequired(podcast: podcast) { _ in
                    //TODO: trigger refresh here?
                }
                continuation.resume(with: .success(podcast))
                return
            }

            serverPodcastManager.addFromUuid(podcastUuid: podcastUuid, subscribe: false, completion: { success in
                if success, let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
                    continuation.resume(with: .success(podcast))
                } else {
                    continuation.resume(with: .success(nil))
                }
            })
        }
    }


    private func fetchEpisodes() -> [Episode] {
        guard let podcast else {
            return []
        }
        return dataManager.allEpisodesForPodcast(id: podcast.id)
    }

    var isFollowing: Bool {
        if let podcast {
            return podcast.isSubscribed()
        } else {
            return false
        }
    }

    func follow() {
        if let podcast {
            podcast.subscribed = 0
        }
    }
}
