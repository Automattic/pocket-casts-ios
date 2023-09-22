import PocketCastsDataModel
import PocketCastsUtils

@available(iOS 17, *)
extension PlayEpisodeIntent {
    func intentPlayback(_ episodeUuid: String) {
        FileLog.shared.addMessage("PlayEpisodeIntent called for episode \(episodeUuid)")

        guard let podcastEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) else {
            FileLog.shared.addMessage("PlayEpisodeIntent error: episode not found")
            return
        }

        AnalyticsPlaybackHelper.shared.currentSource = .interactiveWidget
        let current = PlaybackManager.shared.currentEpisode()

        if current?.uuid == podcastEpisode.uuid {
            PlaybackActionHelper.playPause()
        } else {
            // Ideally we should use PlaybackActionHelper here
            // However this can potentially triger an UI and does a lot of other checks
            // that is not as performant as this call.
            PlaybackManager.shared.load(episode: podcastEpisode, autoPlay: true, overrideUpNext: false)
        }
    }
}
