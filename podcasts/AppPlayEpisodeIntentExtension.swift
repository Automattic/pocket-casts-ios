import PocketCastsDataModel

extension PlayEpisodeIntent {
    func intentPlayback(_ episodeUuid: String) {
        print("In App intent extension \(episodeUuid)")

        guard let podcastEpisode = DataManager.sharedManager.findEpisode(uuid: episodeUuid) else {
            print("episode not found")
            return
        }

        let current = PlaybackManager.shared.currentEpisode()

        if PlaybackManager.shared.playing() && current?.uuid == podcastEpisode.uuid {
            PlaybackManager.shared.pause()
        } else {
            PlaybackManager.shared.load(episode: podcastEpisode, autoPlay: true, overrideUpNext: false)
        }
    }
}
