import Foundation

@testable import PocketCastsDataModel

class EpisodeBuilder {
    var episode = Episode()

    func with(playedUpTo: Double) -> Self {
        episode.playedUpTo = playedUpTo
        return self
    }

    func with(lastPlaybackInteractionDate: Date) -> Self {
        episode.lastPlaybackInteractionDate = lastPlaybackInteractionDate
        return self
    }

    func build() -> Episode {
        episode
    }
}
