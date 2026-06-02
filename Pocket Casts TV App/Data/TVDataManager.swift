import PocketCastsDataModel
import PocketCastsServer

class TVDataManager {

    static let shared = TVDataManager()

    private let dataManager: DataManager
    private let serverPodcastManager: ServerPodcastManager
    private let playbackManager: PlaybackManager

    init(dataManager: DataManager = DataManager.sharedManager,
         serverPodcastManager: ServerPodcastManager = ServerPodcastManager.shared,
         playbackManager: PlaybackManager = PlaybackManager.shared
    ) {
        self.dataManager = dataManager
        self.serverPodcastManager = serverPodcastManager
        self.playbackManager = playbackManager
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

    func fetchEpisodes(podcast: Podcast?, sortOrder: PodcastEpisodeSortOrder? = nil) -> [Episode] {
        guard let podcast else {
            return []
        }
        let (query, arguments) = EpisodesQueryBuilder.makeEpisodeQuery(podcast: podcast, sortOrder: sortOrder)
        return dataManager.findEpisodesWhere(customWhere: query, arguments: arguments)
    }

    func playLatestEpisode(of podcast: DiscoverPodcast) async -> Bool {
        guard let podcastUuid = podcast.uuid else {
            return false
        }
        let podcast = await loadPodcast(podcastUuid: podcastUuid)

        guard let episode = fetchEpisodes(podcast: podcast, sortOrder: .newestToOldest).first else {
            return false
        }
        guard !playbackManager.isActivelyPlaying(episodeUuid: episode.uuid) else {
            return false
        }

        PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        return true
    }

    func playEpisode(_ episode: DiscoverEpisode) async -> Bool {
        guard let podcastUuid = episode.podcastUuid else {
            return false
        }
        let podcast = await loadPodcast(podcastUuid: podcastUuid)

        guard let episode = fetchEpisodes(podcast: podcast, sortOrder: .newestToOldest).first(where: { $0.uuid == episode.uuid }) else {
            return false
        }

        guard !playbackManager.isActivelyPlaying(episodeUuid: episode.uuid) else {
            return false
        }

        PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        return true
    }
}
