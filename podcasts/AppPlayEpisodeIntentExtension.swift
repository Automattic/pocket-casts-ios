import PocketCastsDataModel
import PocketCastsUtils

@available(iOS 17, *)
extension PlayEpisodeIntent {
    func intentPlayback(_ episodeUuid: String) {
        FileLog.shared.addMessage("PlayEpisodeIntent called for episode \(episodeUuid)")

        guard let podcastEpisode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else {
            FileLog.shared.addMessage("PlayEpisodeIntent error: episode not found")
            return
        }

        let current = PlaybackManager.shared.currentEpisode()

        if current?.uuid == podcastEpisode.uuid {
            PlaybackActionHelper.playPause()
        } else {
            PlaybackActionHelper.play(episode: podcastEpisode, playlist: .none)
        }
    }
}
