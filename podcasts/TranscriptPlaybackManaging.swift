protocol TranscriptPlaybackManaging {
    var episodeUUID: String? { get }
    var podcastUUID: String? { get }
    var parentIdentifier: String? { get }
    var isPlayingEpisode: Bool { get }
    var canSeek: Bool { get }

    func currentTime() -> TimeInterval
    func seekTo(time: TimeInterval)
}

extension PlaybackManager: TranscriptPlaybackManaging {
    var episodeUUID: String? {
        currentEpisode()?.uuid
    }

    var parentIdentifier: String? {
        currentEpisode()?.parentIdentifier()
    }

    var podcastUUID: String? {
        currentPodcast?.uuid
    }

    var isPlayingEpisode: Bool {
        isActivelyPlaying(episodeUuid: episodeUUID)
    }

    var canSeek: Bool { true }

    func seekTo(time: TimeInterval) {
        seekTo(time: time, startPlaybackAfterSeek: false, seekHint: nil)
    }
}

struct TranscriptEpisodeInfoProvider: TranscriptPlaybackManaging {
    let episodeUUID: String?
    let podcastUUID: String?

    var parentIdentifier: String? {
        podcastUUID
    }

    init(episodeUUID: String, podcastUUID: String) {
        self.episodeUUID = episodeUUID
        self.podcastUUID = podcastUUID
    }

    func currentTime() -> TimeInterval {
        guard PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episodeUUID) else {
            return 0
        }
        return PlaybackManager.shared.currentTime()
    }

    func seekTo(time: TimeInterval) {
        guard PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episodeUUID) else { return }
        PlaybackManager.shared.seekTo(time: time)
    }

    var canSeek: Bool { PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episodeUUID) }

    var isPlayingEpisode: Bool {
        PlaybackManager.shared.isActivelyPlaying(episodeUuid: episodeUUID)
    }
}
