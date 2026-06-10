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

    var isShowingReplaceUpNextConfirmation = false
    var isShowingNowPlaying = false

    let playlist: EpisodeFilter
    var episodes: [Episode] = []
    var showArchived: Bool = false

    private var allEpisodes: [Episode] = []
    private let dataManager: DataManager
    private let playbackManager: PlaybackManager

    private static func archiveStorageKey(for playlist: EpisodeFilter) -> String {
        "showArchived_playlist_\(playlist.uuid)"
    }

    init(playlist: EpisodeFilter,
         dataManager: DataManager = DataManager.sharedManager,
         playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.playbackManager = playbackManager
        self.showArchived = UserDefaults.standard.bool(forKey: Self.archiveStorageKey(for: playlist))
    }

    func load() {
        Task {
            // `DataManager.playlistEpisodes(for:)` always filters archived out, so go through the
            // query builder directly with `shouldShowArchived: true` to keep archived episodes in
            // `allEpisodes` and let the local toggle decide what to display.
            let query = PlaylistQueryBuilder.query(
                clause: .episode,
                for: playlist,
                limit: Self.playlistEpisodeLimit,
                shouldShowArchived: true
            )
            let playlistEpisodes = dataManager.findPlaylistEpisodesWhere(query: query, arguments: nil)
            await MainActor.run {
                allEpisodes = playlistEpisodes
                applyArchivedFilter()
                state = .ready
            }
        }
    }

    /// Mirrors `EpisodeDataManager.Constants.Limits.maxPlaylistItems`, which is private to the data module.
    private static let playlistEpisodeLimit = 1000

    func setShowArchived(_ value: Bool) {
        showArchived = value
        applyArchivedFilter()
        UserDefaults.standard.set(value, forKey: Self.archiveStorageKey(for: playlist))
    }

    private func applyArchivedFilter() {
        episodes = showArchived ? allEpisodes : allEpisodes.filter { !$0.archived }
    }

    func playAll() {
        guard !episodes.isEmpty else { return }

        if playbackManager.playIfSafe(playlist: playlist, episodeIDs: episodes.map(\.uuid)) {
            isShowingNowPlaying = true
        } else {
            isShowingReplaceUpNextConfirmation = true
        }
    }

    func buttonConfirmPlayPlaylistTapped() {
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
