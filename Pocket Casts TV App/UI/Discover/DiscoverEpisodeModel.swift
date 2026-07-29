import UIKit
import AVFoundation
import PocketCastsServer
import PocketCastsUtils

@Observable
class DiscoverEpisodeModel {

    private let discoverManager: DiscoverManager

    private let playbackManager: PlaybackManager

    let episode: DiscoverEpisode

    var isPlaying: Bool = false

    init(episode: DiscoverEpisode,
         discoverManager: DiscoverManager = DiscoverManager.shared,
         playbackManager: PlaybackManager = .shared) {
        self.episode = episode
        self.discoverManager = discoverManager
        self.playbackManager = playbackManager
    }

    func load() async {

    }

    var podcast: DiscoverPodcast? {
        episode.discoverPodcast
    }
}
