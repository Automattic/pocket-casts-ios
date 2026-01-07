import PocketCastsDataModel
import PocketCastsUtils

@available(iOS 17, *)
extension PlayEpisodeIntent {
    func intentPlayback(_ episodeUuid: String) {
        // Log to both FileLog (main app) and WidgetLog (shared with app)
        FileLog.shared.addMessage("PlayEpisodeIntent called for episode \(episodeUuid)")
        WidgetLog.shared.addMessage("PlayEpisodeIntent called for episode \(episodeUuid)")

        guard let podcastEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else {
            FileLog.shared.addMessage("PlayEpisodeIntent error: episode not found")
            WidgetLog.shared.addMessage("ERROR: Episode not found - \(episodeUuid)")
            return
        }

        AnalyticsPlaybackHelper.shared.currentSource = .interactiveWidget
        let current = PlaybackManager.shared.currentEpisode()

        if current?.uuid == podcastEpisode.uuid {
            let action = PlaybackManager.shared.playing() ? "pause" : "play"
            WidgetLog.shared.addMessage("Toggling playback: \(action)")
            Analytics.track(.widgetInteraction, properties: ["action": action])
            PlaybackActionHelper.playPause()
        } else {
            WidgetLog.shared.addMessage("Loading new episode: \(podcastEpisode.displayableTitle())")
            // Ideally we should use PlaybackActionHelper here
            // However this can potentially trigger an UI and does a lot of other checks
            // that is not as performant as this call.
            PlaybackManager.shared.load(episode: podcastEpisode, autoPlay: true, overrideUpNext: false)
            Analytics.track(.widgetInteraction, properties: ["action": "play"])
        }
    }
}
