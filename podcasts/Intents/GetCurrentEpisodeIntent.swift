import AppIntents
import PocketCastsDataModel

@available(iOS 17, *)
struct GetCurrentEpisodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current episode"
    static var description = IntentDescription("Gets the currently playing episode")
    static var isDiscoverable = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<EpisodeSearchEntity?> {
        guard let currentEpisode = PlaybackManager.shared.currentEpisode() else {
            return .result(value: nil)
        }
        
        let podcastTitle: String
        let podcastUuid: String
        
        if let episode = currentEpisode as? Episode, let podcast = episode.parentPodcast() {
            podcastTitle = podcast.title ?? ""
            podcastUuid = podcast.uuid
        } else {
            // User episode or fallback
            podcastTitle = "User Files"
            podcastUuid = ""
        }
        
        let episodeEntity = EpisodeSearchEntity(
            episodeUuid: currentEpisode.uuid,
            title: currentEpisode.title ?? "",
            podcastTitle: podcastTitle,
            podcastUuid: podcastUuid
        )
        
        return .result(value: episodeEntity)
    }
}
