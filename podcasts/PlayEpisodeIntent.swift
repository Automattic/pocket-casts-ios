import AppIntents
import WidgetKit
import os
import PocketCastsDataModel

struct PlayEpisodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Play episode"

    @Parameter(title: "Episode")
    var episode: EpisodeEntity

    @Parameter(title: "Play")
    var play: Bool

    init() {}

    init(episode: EpisodeEntity, play: Bool) {
        self.episode = episode
        self.play = play
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let message = "testing message in intent"
        Logger().log("\(message, privacy: .public)")
        if play {
            print("Play episode \(episode.id)")
        } else {
            print("PAUSE episode \(episode.id)")
        }

        // TODO: HOW TO DO THIS WITHOUT ADDING ALL THE NECESSARY DEPENDENCIES???
        // can I fire some "notification" to trigger it? Media Playback Intent?
//        let podcastEpisode = DataManager.sharedManager.findEpisode(uuid: episode.id.uuidString)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playbackRequested, object: episode.id.uuidString)

//        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.id.uuidString) {
//            PlaybackActionHelper.playPause()
//        } else {
//            PlaybackActionHelper.play(episode: podcastEpisode!)
//        }

        return .result(value: episode)
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
        // TODO: return episode entities that are needed, or all episodes since this could be an UpNext or a playlist?
        DataManager.sharedManager.allUpNextEpisodes().map( { EpisodeEntity(id: UUID(uuidString: $0.uuid )!) } )
    }
}
