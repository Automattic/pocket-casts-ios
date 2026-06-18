import SwiftUI
import Combine
import PocketCastsUtils
import PocketCastsDataModel

@Observable
class PlaylistDetailsViewModel {

    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    /// Bumped when a podcast colour download lands so `playlistColor` re-runs
    /// against the freshly-updated row instead of the stale defaults.
    private var colorRefreshTrigger: Int = 0

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
        observePodcastColorDownloads()
    }

    /// Newly-subscribed podcasts arrive with `colorVersion = 1`, so the
    /// initial `ColorManager` lookup returns defaults and schedules a
    /// background colour download. Listen for the resulting notification so
    /// the pill can refresh its background once the metadata lands.
    private func observePodcastColorDownloads() {
        NotificationCenter.default
            .publisher(for: Constants.Notifications.podcastColorsDownloaded)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard
                    let self,
                    let uuid = notification.object as? String,
                    self.episodes.first?.podcastUuid == uuid
                else { return }
                self.colorRefreshTrigger &+= 1
            }
            .store(in: &cancellables)
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
        guard value != showArchived else { return }
        Analytics.track(value ? .filterShowArchivedTapped : .filterHideArchivedTapped)
        showArchived = value
        applyArchivedFilter()
        UserDefaults.standard.set(value, forKey: Self.archiveStorageKey(for: playlist))
    }

    private func applyArchivedFilter() {
        episodes = showArchived ? allEpisodes : allEpisodes.filter { !$0.archived }
    }

    func playAll() {
        guard !episodes.isEmpty else { return }

        Analytics.track(.filterPlayAllTapped)

        if playbackManager.playIfSafe(playlist: playlist, episodeIDs: episodes.map(\.uuid)) {
            isShowingNowPlaying = true
        } else {
            isShowingReplaceUpNextConfirmation = true
        }
    }

    func buttonConfirmPlayPlaylistTapped() {
        Analytics.track(.filterPlayAllReplaceAndPlayTapped, properties: ["save_up_next": Settings.saveCurrentUpNextQueueIntoPlaylist])
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

    /// Pill background colour. Pulled from the podcast whose artwork sits on
    /// the front of the cover stack so the pill visually echoes that image.
    /// Falls back to a deterministic palette while episodes haven't loaded,
    /// for an empty playlist with no cover to sample, or when the server
    /// hasn't provided usable colour metadata for the front cover podcast.
    var playlistColor: Color {
        // Touch the trigger so `@Observable` re-runs this getter when a
        // delayed colour download lands.
        _ = colorRefreshTrigger
        if let uuid = episodes.first?.podcastUuid,
           let podcast = dataManager.findPodcast(uuid: uuid, includeUnsubscribed: true),
           let color = Self.pillColor(from: ColorManager.lightThemeTintForPodcast(podcast)) {
            return color
        }
        return Self.fallbackPillColor(for: playlist.uuid)
    }

    /// Reshape a podcast tint into something legible as a card background:
    /// keep the hue, clamp the saturation/brightness into a calm-but-vivid
    /// range. Returns `nil` for tints with no usable chroma (greys, near
    /// black) — `getHue` reports `H = 0` on a grey, so a naïve saturation
    /// floor would convert every metadata-less podcast into brown.
    private static func pillColor(from tint: UIColor) -> Color? {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        tint.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        guard s > 0.15, b > 0.1 else { return nil }
        return Color(UIColor(
            hue: h,
            saturation: min(max(s, 0.5), 0.85),
            brightness: min(max(b, 0.3), 0.45),
            alpha: a
        ))
    }

    /// Deterministic per-seed palette so playlists whose front cover has no
    /// usable colour metadata still render distinct from each other.
    private static func fallbackPillColor(for seed: String) -> Color {
        let palette: [Color] = [
            Color(red: 0.15, green: 0.25, blue: 0.5),
            Color(red: 0.5, green: 0.17, blue: 0.15),
            Color(red: 0.21, green: 0.22, blue: 0.14),
            Color(red: 0.5, green: 0.35, blue: 0.12),
            Color(red: 0.15, green: 0.4, blue: 0.3),
            Color(red: 0.3, green: 0.2, blue: 0.45)
        ]
        // `String.hashValue` is per-run randomised in Swift; sum the unicode
        // scalars instead so a given playlist gets the same pill colour each
        // launch.
        let index = seed.unicodeScalars.reduce(0) { $0 + Int($1.value) } % palette.count
        return palette[index]
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
