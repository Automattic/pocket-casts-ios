import SwiftUI
import Combine
import PocketCastsUtils
import PocketCastsDataModel

@Observable
class PlaylistDetailsViewModel {

    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

    enum State: Equatable, Hashable {
        case loading
        case empty
        case ready
    }

    var state: State = .loading

    var isShowingReplaceUpNextConfirmation = false
    var isShowingNowPlaying = false

    var playlist: PlaylistItem
    var episodes: [Episode] = []
    var showArchived: Bool = false
    var playlistColor: Color
    var episodesCount: Int = 0

    var hasDownloadFilter: Bool { playlist.playlist.isDownloadFilterActive }

    private var allEpisodes: [Episode] = []
    private let dataManager: DataManager
    private let playbackManager: PlaybackManager

    private static func archiveStorageKey(for playlist: EpisodeFilter) -> String {
        "showArchived_playlist_\(playlist.uuid)"
    }

    init(playlist: PlaylistItem,
         detail: Bool = false,
         dataManager: DataManager = DataManager.sharedManager,
         playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.playlist = playlist
        self.dataManager = dataManager
        self.playbackManager = playbackManager
        self.showArchived = UserDefaults.standard.bool(forKey: Self.archiveStorageKey(for: playlist.playlist))
        self.playlistColor = Self.fallbackPillColor(for: playlist.playlist.uuid)
        observePodcastColorDownloads()
        if detail {
            observePlaylistChanges()
        }
    }

    /// Newly-subscribed podcasts return defaults until colour metadata downloads — refresh
    /// the pill when that happens.
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
                self.refreshPlaylistColor()
            }
            .store(in: &cancellables)
    }

    private func observePlaylistChanges() {
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: Constants.Notifications.playlistChanged),
            NotificationCenter.default.publisher(for: Constants.Notifications.episodeArchiveStatusChanged),
            NotificationCenter.default.publisher(for: Constants.Notifications.episodePlayStatusChanged),
        )
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.load()
        }
        .store(in: &cancellables)
    }

    func load() {
        Task {
            // `DataManager.playlistEpisodes(for:)` always filters archived out, so query directly
            // with `shouldShowArchived` depending of the list type and let the local toggle decide what to display.
            let query = PlaylistQueryBuilder.query(
                clause: .episode,
                for: playlist.playlist,
                limit: Self.playlistEpisodeLimit,
                shouldShowArchived: playlist.playlist.manual
            )
            let playlistEpisodes = dataManager.findPlaylistEpisodesWhere(query: query, arguments: nil)
            let count = dataManager.allPlaylistEpisodeCount(for: playlist.playlist, episodeUuidToAdd: nil, includingArchivedEpisodes: playlist.playlist.manual)
            await MainActor.run {
                allEpisodes = playlistEpisodes
                episodesCount = count
                applyArchivedFilter()
                refreshPlaylistColor()
                state = playlistEpisodes.isEmpty ? .empty : .ready
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
        refreshPlaylistColor()
        UserDefaults.standard.set(value, forKey: Self.archiveStorageKey(for: playlist.playlist))
    }

    private func applyArchivedFilter() {
        episodes = showArchived ? allEpisodes : allEpisodes.filter { !$0.archived }
    }

    func playAll() {
        guard !episodes.isEmpty else { return }

        Analytics.track(.filterPlayAllTapped, properties: analyticsProperties())

        if playbackManager.playIfSafe(playlist: playlist.playlist, episodeIDs: episodes.map(\.uuid)) {
            isShowingNowPlaying = true
        } else {
            isShowingReplaceUpNextConfirmation = true
        }
    }

    func saveUpNextAndPlay() {
        Analytics.track(.filterPlayAllReplaceAndPlayTapped, properties: analyticsProperties(["save_up_next": true]))
        Task { await _saveUpNextAndPlay() }
    }

    @concurrent private func _saveUpNextAndPlay() async {
        let episodes = currentUpNextEpisodes()
        let baseName = "\(L10n.upNext) - \(Date().monthDayString())"
        let created = dataManager.createManualPlaylists(from: episodes, batchSize: Constants.Limits.maxFilterItems, baseName: baseName)
        await MainActor.run {
            self.playbackManager.play(playlist: self.playlist.playlist)
            self.isShowingNowPlaying = true

            if created > 0 {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)
                ToastManager.shared.show(created > 1 ? L10n.playlistPlayAllUpNextSavedPlural : L10n.playlistPlayAllUpNextSaved)
            }
        }
    }

    func playWithoutSaving() {
        Analytics.track(.filterPlayAllReplaceAndPlayTapped, properties: analyticsProperties(["save_up_next": false]))
        playbackManager.play(playlist: playlist.playlist)
        isShowingNowPlaying = true
    }

    func replaceUpNextConfirmationDismissed() {
        Analytics.track(.filterPlayAllDismissed, properties: analyticsProperties())
    }

    private func analyticsProperties(_ additional: [String: Sendable] = [:]) -> [String: Sendable] {
        var properties: [String: Sendable] = ["filter_type": isManual ? "manual" : "smart"]
        additional.forEach { properties[$0.key] = $0.value }
        return properties
    }

    private func currentUpNextEpisodes() -> [Episode] {
        let uuids = dataManager.allUpNextEpisodeUuids().compactMap(\.uuid)
        return dataManager.allUpNextEpisodes(from: uuids)
    }

    var playlistName: String {
        return playlist.playlist.playlistName
    }

    var isManual: Bool {
        return playlist.playlist.manual
    }

    var totalDuration: String {
        let total = episodes.reduce(0) { $0 + $1.duration }
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: total)
    }

    var episodeCountText: String {
        return episodesCount == 1 ? L10n.podcastEpisodeCountSingular : L10n.podcastEpisodeCountPluralFormat(episodesCount.localized())
    }

    var allEpisodesCount: Int {
        return episodesCount
    }

    var areAllEpisodesArchived: Bool {
        return episodes.isEmpty && !allEpisodes.isEmpty
    }

    private func refreshPlaylistColor() {
        if let uuid = episodes.first?.podcastUuid,
           let podcast = dataManager.findPodcast(uuid: uuid, includeUnsubscribed: true),
           let color = Self.pillColor(from: ColorManager.lightThemeTintForPodcast(podcast)) {
            playlistColor = color
        } else {
            playlistColor = Self.fallbackPillColor(for: playlist.playlist.uuid)
        }
    }

    /// Returns `nil` for tints with no usable chroma — `getHue` reports `H = 0` for greys,
    /// so a naïve saturation floor would turn every metadata-less podcast brown.
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

    private static let fallbackPalette: [Color] = [
        Color(red: 0.15, green: 0.25, blue: 0.5),
        Color(red: 0.5, green: 0.17, blue: 0.15),
        Color(red: 0.21, green: 0.22, blue: 0.14),
        Color(red: 0.5, green: 0.35, blue: 0.12),
        Color(red: 0.15, green: 0.4, blue: 0.3),
        Color(red: 0.3, green: 0.2, blue: 0.45)
    ]

    private static func fallbackPillColor(for seed: String) -> Color {
        // `String.hashValue` is per-run randomised; sum unicode scalars for a stable seed.
        let index = seed.unicodeScalars.reduce(0) { $0 + Int($1.value) } % fallbackPalette.count
        return fallbackPalette[index]
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
