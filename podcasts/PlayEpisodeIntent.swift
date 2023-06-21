import AppIntents
import WidgetKit
import os
import PocketCastsDataModel

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
        let message = "testing message in intent"
        Logger().log("\(message, privacy: .public)")
        print("Play episode \(episode.id)")

        // TODO: HOW TO DO THIS WITHOUT ADDING ALL THE NECESSARY DEPENDENCIES???
        // can I fire some "notification" to trigger it? Media Playback Intent?
        let podcastEpisode = DataManager.sharedManager.findEpisode(uuid: episode.id.uuidString)

//        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.id.uuidString) {
//            PlaybackActionHelper.playPause()
//        } else {
//            PlaybackActionHelper.play(episode: podcastEpisode!)
//        }

//        return .result(result: nil, confirmationActionName: "test", showPrompt: true)
        return .result(value: episode, dialog: IntentDialog(stringLiteral: "YO"))
//        return .result(value: "")
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
        
        // TODO: return episode entities that are needed, or all episodes since this could be an UpNext or a playlist?
        return [EpisodeEntity(id: UUID(uuidString:"779ffa58-88e1-4418-b222-fdcee52dd9d3")!), EpisodeEntity(id: UUID(uuidString:"bd82e019-42a8-4f2f-ad82-1d6acfcdd89f")!)]
        
    }
}
