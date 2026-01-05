import AppIntents
import WidgetKit

@available(iOS 17, *)
struct PlayEpisodeIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Play episode"
    static var isDiscoverable = false // for now only to be used in the Now Playing widget

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

        intentPlayback(episodeUuid)

        return .result()
    }
}
