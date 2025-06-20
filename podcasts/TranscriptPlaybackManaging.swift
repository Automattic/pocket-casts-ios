protocol TranscriptPlaybackManaging {
    var episodeUUID: String? { get }
    var podcastUUID: String? { get }
    var parentIdentifier: String? { get }
    var isPlayingEpisode: Bool { get }

    func currentTime() -> TimeInterval
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
        0
    }

    var isPlayingEpisode: Bool {
        PlaybackManager.shared.isActivelyPlaying(episodeUuid: episodeUUID)
    }
}
