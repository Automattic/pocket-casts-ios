import AppIntents
import WidgetKit

struct PlayEpisodeIntent: AudioStartingIntent {
    static var title: LocalizedStringResource = "Play episode"

    @Parameter(title: "EpisodeUUID")
    var episodeUuid: String

    init(episodeUuid: String) {
        self.episodeUuid = episodeUuid
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {

        intentPlayback(episodeUuid)

        return .result()
    }
}
