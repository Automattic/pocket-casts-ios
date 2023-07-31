import AppIntents
import WidgetKit
import os
import PocketCastsDataModel

struct PlayEpisodeIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Play episode"
    static var isDiscoverable = false // for now only to be used in the Now Playing widget

    @Parameter(title: "EpisodeUUID")
    var episodeUuid: String

    // Not actually used anymore
    @Parameter(title: "Play")
    var play: Bool

    init() {}

    init(episodeUuid: String, play: Bool) {
        self.episodeUuid = episodeUuid
        self.play = play
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let message = "testing message in intent"
        Logger().log("\(message, privacy: .public)")
        if play {
            print("Play episode \(episodeUuid)")
        } else {
            print("PAUSE episode \(episodeUuid)")
        }

        // commented out for now while testing / demonstrating Extension idea
        //        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playbackRequested, object: episodeUuid)

        intentPlayback(episodeUuid)

        return .result()
    }
}
