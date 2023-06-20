import AppIntents
import os

struct PlayEpisodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Play episode"

//    @Parameter(title: "Episode", optionsProvider: EpisodeOptionsProvider())
    @Parameter(title: "Episode")
    var episode: EpisodeEntity

    init() {}

    init(episode: EpisodeEntity) {
        self.episode = episode
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // TODO: Play episode
        let message = "testing message in intent"
        Logger().log("\(message, privacy: .public)")
        print("Play episode intent perform")
        print("Play episode \(episode.id)")

//        let podcastEpisode = DataManager.sharedManager.findEpisode(uuid: episode.id.uuidString)

//        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.id.uuidString) {
//            PlaybackActionHelper.playPause()
//        } else {
//            PlaybackActionHelper.play(episode: podcastEpisode!)
//        }

//        return .result(result: nil, confirmationActionName: "test", showPrompt: true)
        return .result(value: episode, dialog: IntentDialog(stringLiteral: "YO"))
    }
}

struct EpisodeEntity: AppEntity, Identifiable {
    static var defaultQuery = EpisodeQuery()

    typealias DefaultQuery = EpisodeQuery

    var id: UUID
//    var title: String

//    var displayRepresentation: DisplayRepresentation { "\(title)" }
    var displayRepresentation: DisplayRepresentation { "hi-title" }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Episode"

//    static var defaultQuery = EpisodeQuery()
}

struct EpisodeQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [EpisodeEntity] {
//        try await MusicCatalog.shared.albums(for: identifiers)
//            .map { AlbumEntity(id: $0.id, albumName: $0.name) }
        return []
    }
}
