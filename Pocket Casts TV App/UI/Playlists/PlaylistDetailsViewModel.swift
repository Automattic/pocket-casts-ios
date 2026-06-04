import SwiftUI
import Combine
import PocketCastsUtils
import PocketCastsDataModel

@Observable
class PlaylistDetailsViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    /// Drives the "Replace your Up Next?" confirmation dialog before playing all episodes.
    var isShowingReplaceUpNextConfirmation = false

    /// Drives the full-screen Now Playing presentation once playback starts.
    var isShowingNowPlaying = false

    let playlist: EpisodeFilter
    var episodes: [Episode] = []

    private let dataManager: DataManager
    private let playbackManager: PlaybackManager

    init(playlist: EpisodeFilter,
         dataManager: DataManager = DataManager.sharedManager,
         playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.playbackManager = playbackManager
    }

    func load() {
        Task {
            let playlistEpisodes = dataManager.playlistEpisodes(for: playlist)
            await MainActor.run {
                episodes = playlistEpisodes
                state = .ready
            }
        }
    }

    func playAll() {
        guard !episodes.isEmpty else { return }

        switch playbackManager.playAllAction(forPlaylistEpisodeIDs: episodes.map(\.uuid)) {
        case .play:
            playAllEpisodes()
        case .confirmReplaceUpNext:
            isShowingReplaceUpNextConfirmation = true
        case .resumeCurrent:
            playbackManager.resumeIfPaused()
            isShowingNowPlaying = true
        }
    }

    func playAllEpisodes() {
        playbackManager.play(playlist: playlist)
        isShowingNowPlaying = true
    }

    var playlistName: String {
        return playlist.playlistName
    }

    var isManual: Bool {
        return playlist.manual
    }

    var totalDuration: String {
        let total = episodes.reduce(0) { $0 + $1.duration }
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: total)
    }

    var episodeCountText: String {
        return L10n.tvPlaylistDetailEpisodeCount(episodes.count)
    }

    var playlistColor: Color {
        return MockData.playlistsSpec[Int(playlist.sortPosition) % MockData.playlistsSpec.count].2
    }

    var coverPodcastsUuids: [String] {
        var seen = Set<String>()
        var unique = [String]()
        for episode in episodes {
            if seen.insert(episode.podcastUuid).inserted {
                unique.append(episode.podcastUuid)
            }
            if unique.count == 4 { break }
        }
        return unique
    }
}
