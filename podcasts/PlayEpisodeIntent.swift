import AppIntents
import WidgetKit
import PocketCastsUtils

struct PlayEpisodeIntent: AudioStartingIntent {
    static var title: LocalizedStringResource = "Play episode"

    @Parameter(title: "EpisodeUUID")
    var episodeUuid: String

    init(episodeUuid: String) {
        self.episodeUuid = episodeUuid
    }

    init() {}

    static var openAppWhenRun: Bool { return false }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { return [.background] }

    @MainActor
    func perform() async throws -> some IntentResult {
        FileLog.shared.addMessage("PlayEpisodeIntent perform called for episode \(episodeUuid)")
        intentPlayback(episodeUuid)

        return .result()
    }
}
