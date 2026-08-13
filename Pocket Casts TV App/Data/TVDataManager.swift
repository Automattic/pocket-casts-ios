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

    @concurrent func loadPodcast(podcastUuid: String) async -> Podcast? {
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

    @concurrent func fetchEpisodes(podcast: Podcast?, sortOrder: PodcastEpisodeSortOrder? = nil, includeArchived: Bool = false) async -> [Episode] {
        guard let podcast else {
            return []
        }
        let (query, arguments) = EpisodesQueryBuilder.makeEpisodeQuery(podcast: podcast, sortOrder: sortOrder, includeArchived: includeArchived)
        return dataManager.findEpisodesWhere(customWhere: query, arguments: arguments)
    }

    func playLatestEpisode(of podcast: DiscoverPodcast) async -> Bool {
        guard let podcastUuid = podcast.uuid else {
            return false
        }
        let podcast = await loadPodcast(podcastUuid: podcastUuid)

        guard let episode = await fetchEpisodes(podcast: podcast, sortOrder: .newestToOldest).first else {
            return false
        }
        guard !playbackManager.isActivelyPlaying(episodeUuid: episode.uuid) else {
            return false
        }

        await PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        return true
    }

    func playEpisode(_ episode: DiscoverEpisode) async -> Bool {
        guard let podcastUuid = episode.podcastUuid, let episodeUuid = episode.uuid else {
            return false
        }
        return await playEpisode(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
    }

    @concurrent func loadEpisode(podcastUuid: String, episodeUuid: String) async -> (episode: Episode, podcast: Podcast?)? {
        let podcast = await loadPodcast(podcastUuid: podcastUuid)

        guard let episode = dataManager.findEpisode(uuid: episodeUuid) else {
            return nil
        }

        return (episode, podcast)
    }

    func playEpisode(podcastUuid: String, episodeUuid: String) async -> Bool {
        guard let (episode, _) = await loadEpisode(podcastUuid: podcastUuid, episodeUuid: episodeUuid) else {
            return false
        }

        //if we are already playing the episode let's return true
        guard !playbackManager.isActivelyPlaying(episodeUuid: episode.uuid) else {
            return true
        }

        await PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        return true
    }

    func playEpisode(_ episode: EpisodeSearchResult) async -> Bool {
        guard !episode.podcastUuid.isEmpty, !episode.uuid.isEmpty else {
            return false
        }
        return await playEpisode(podcastUuid: episode.podcastUuid, episodeUuid: episode.uuid)
    }
}
