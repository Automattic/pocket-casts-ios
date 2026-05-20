import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@Observable
class PodcastDetailViewModel {

    private let dataManager: DataManager
    private let serverPodcastManager: ServerPodcastManager
    private let podcastManager: PodcastManager

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
    var isFollowing: Bool = false

    init(podcastUuid: String,
         dataManager: DataManager = DataManager.sharedManager,
         serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared,
         podcastManager: PodcastManager = PodcastManager.shared) {
        self.podcastUuid = podcastUuid
        self.dataManager = dataManager
        self.serverPodcastManager = serverPodcastManager
        self.podcastManager = podcastManager
    }

    convenience init(podcast: Podcast,
                     dataManager: DataManager = DataManager.sharedManager,
                     serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared,
                     podcastManager: PodcastManager = PodcastManager.shared) {
        self.init(podcastUuid: podcast.uuid,
                  dataManager: dataManager,
                  serverPodcastManager: serverPodcastManager,
                  podcastManager: podcastManager)
        self.podcast = podcast
    }

    func load() {
        Task {
            if podcast == nil {
                podcast = await loadPodcast(podcastUuid: podcastUuid)
            }
            guard let podcast else {
                await MainActor.run { state = .failed }
                return
            }
            let episodesModel = fetchEpisodes().map {
                EpisodeRowViewModel(episode: $0, podcast: podcast)
            }
            await MainActor.run {
                isFollowing = podcast.subscribed != 0
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

            serverPodcastManager.addFromUuid(podcastUuid: podcastUuid, subscribe: false, completion: { [dataManager] success in
                if success, let podcast = dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
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

    func subscribe() {
        guard let podcast else { return }
        isFollowing = true
        serverPodcastManager.subscribe(to: podcast.uuid, completion: nil)
    }

    func unsubscribe() {
        guard let podcast else { return }
        isFollowing = false
        podcastManager.unsubscribe(podcast: podcast)
    }
}
