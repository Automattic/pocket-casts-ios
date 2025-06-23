import PocketCastsDataModel
import AppIntents
import PocketCastsUtils

@available(iOS 18.2, *)
@AppEnum(schema: .reader.documentKind)
enum EpisodeDocumentKind: String, AppEnum, Codable {
    case text

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .text: .init(title: "Text", image: .init(systemName: "doc.text")),
        ]
    }
}

@available(iOS 18.2, *)
@AppEntity(schema: .reader.document)
struct EpisodeEntity: AppEntity {
    static let defaultQuery = EpisodeEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(stringLiteral: "Episode")

    var kind: EpisodeDocumentKind
    var width: Int?
    var height: Int?

    var id: String

    @Property(title: "Title of episode")
    var title: String

    @Property(title: "Podcast")
    var podcast: PodcastEntity?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            stringLiteral: title
        )
    }
}

@available(iOS 18.2, *)
extension EpisodeEntity {
    init(_ baseEpisode: BaseEpisode) {
        id = baseEpisode.uuid
        title = baseEpisode.title ?? ""
        kind = .text
        width = 400
        height = 10000
//        podcast = PodcastEntity(baseEpisode.podcast)
    }

    init(_ episode: Episode) {
        id = episode.uuid
        title = episode.title ?? ""
        if let parentPodcast = episode.parentPodcast() {
            podcast = PodcastEntity(parentPodcast)
        }
    }
}

@available(iOS 18.2, *)
struct EpisodeEntityQuery: EntityQuery {
    func entities(for identifiers: [EpisodeEntity.ID]) async throws -> [EpisodeEntity] {
        let baseEpisodes = identifiers.compactMap { DataManager.sharedManager.findEpisode(uuid: $0) }
        return baseEpisodes.map { EpisodeEntity($0) }
    }
}

@available(iOS 18.2, *)
struct PlayNewEpisodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Play New Episode"

    @Parameter(title: "Episode")
    var episode: EpisodeEntity

    func perform() async throws -> some IntentResult {
        let episodeUuid = episode.id

        FileLog.shared.addMessage("PlayEpisodeIntent called for episode \(episodeUuid)")

        guard let podcastEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else {
            FileLog.shared.addMessage("PlayEpisodeIntent error: episode not found")
            return .result()
        }

        AnalyticsPlaybackHelper.shared.currentSource = .interactiveWidget
        let current = PlaybackManager.shared.currentEpisode()

        if current?.uuid == podcastEpisode.uuid {
            Analytics.track(.widgetInteraction, properties: ["action": PlaybackManager.shared.playing() ? "pause" : "play"])
            PlaybackActionHelper.playPause()
        } else {
            // Ideally we should use PlaybackActionHelper here
            // However this can potentially trigger an UI and does a lot of other checks
            // that is not as performant as this call.
            PlaybackManager.shared.load(episode: podcastEpisode, autoPlay: true, overrideUpNext: false)
            Analytics.track(.widgetInteraction, properties: ["action": "play"])
        }

        return .result()
    }
}

@available(iOS 18.2, *)
struct ShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PlayNewEpisodeIntent(), phrases: ["Play \(\.$episode) on \(.applicationName)"])
    }
}
