import PocketCastsDataModel
import PocketCastsServer

class PodcastDataManager {

    static let shared = PodcastDataManager()

    private let dataManager: DataManager
    private let serverPodcastManager: ServerPodcastManager

    init(dataManager: DataManager = DataManager.sharedManager, serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared) {
        self.dataManager = dataManager
        self.serverPodcastManager = serverPodcastManager
    }

    func loadPodcast(podcastUuid: String) async -> Podcast? {
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

    func fetchEpisodes(podcast: Podcast?) -> [Episode] {
        guard let podcast else {
            return []
        }
        let (query, arguments) = EpisodesQueryBuilder.makeEpisodeQuery(podcast: podcast)
        return dataManager.findEpisodesWhere(customWhere: query, arguments: arguments)
    }

    func playLatestEpisode(of podcast: DiscoverPodcast) async -> Bool {
        guard let podcastUuid = podcast.uuid else {
            return false
        }
        let podcast = await loadPodcast(podcastUuid: podcastUuid)

        guard let episode = fetchEpisodes(podcast: podcast).first else {
            return false
        }
        guard !PlaybackManager.shared.isActivelyPlaying(episodeUuid: episode.uuid) else {
            return false
        }

        PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        return true
    }
}
