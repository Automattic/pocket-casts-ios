import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI
import Combine

@Observable
class EpisodeRowViewModel: Identifiable {

    static func == (lhs: EpisodeRowViewModel, rhs: EpisodeRowViewModel) -> Bool {
        return lhs.episode.uuid == rhs.episode.uuid
    }

    var episode: BaseEpisode
    var podcast: Podcast?
    var progress: Double
    var id: String { episode.uuid }
    var isDiscover: Bool
    var source: AnalyticsSource

    private var cancellables: Set<AnyCancellable> = []
    private let playbackManager: PlaybackManager

    init(episode: BaseEpisode, podcast: Podcast?, isDiscover: Bool = false, source: AnalyticsSource, playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.episode = episode
        self.podcast = podcast
        self.source = source
        self.playbackManager = playbackManager
        self.progress = 0
        self.isDiscover = isDiscover
        setupObservers()
        self.progress = calculateSafeProgress(from: episode)
    }

    var duration: Double {
        return episode.duration
    }

    var playedUpTo: Double {
        return episode.playedUpTo
    }

    var displayTitle: String {
        return episode.displayableTitle()
    }

    var displaySubTitle: String {
        return episode.subTitle()
    }

    var displayInfo: String {
        return episode.displayableInfo()
    }

    var displayDate: String {
        return DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase
    }

    var displayDuration: String {
        return episode.displayableDuration
    }

    var timeLeft: String {
        return episode.displayableTimeLeft()
    }

    var currentPodcastTintColor: Color? {
        if let podcast {
            return Color(ColorManager.darkThemeTintForPodcast(podcast))
        } else if let episode = episode as? UserEpisode, episode.imageColor > 0 {
            return Color(AppTheme.userEpisodeColor(number: Int(episode.imageColor)))
        } else {
            return Color(AppTheme.userEpisodeColor(number: 1))
        }
    }

    var podcastUuid: String? {
        if let episode = episode as? Episode {
            return episode.podcastUuid
        } else {
            return nil
        }
    }

    @MainActor
    func play() {
        guard !playbackManager.isActivelyPlaying(episodeUuid: episode.uuid) else { return }
        AnalyticsPlaybackHelper.shared.currentSource = source
        PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
        if isDiscover, let podcastUuid {
            DiscoverAnalytics.discoverPodcastPlayed(podcastUuid: podcastUuid)
        }
    }

    func playNext() {
        EpisodeUpNextActions.playNext(episode, playbackManager: playbackManager)
    }

    func playLast() {
        EpisodeUpNextActions.playLast(episode, playbackManager: playbackManager)
    }

    func markAsPlayed() {
        EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeMarkedAsPlayed)
    }

    func markAsUnplayed() {
        EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeMarkedAsUnplayed)
    }

    var isPlayed: Bool {
        episode.played()
    }

    var canArchive: Bool {
        episode is Episode
    }

    var isArchived: Bool {
        (episode as? Episode)?.archived ?? false
    }

    var isVideo: Bool {
        return EpisodeManager.isVideo(episode)
    }

    func archive() {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeArchived)
    }

    func unarchive() {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.unarchiveEpisode(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeUnarchived)
    }

    func removeFromUpNext() {
        playbackManager.removeIfPlayingOrQueued(episode: episode, fireNotification: true, userInitiated: true)
        ToastManager.shared.show(L10n.tvEpisodeRemovedFromUpNext)
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: Constants.Notifications.playbackProgress)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateProgress()
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.episodeArchiveStatusChanged)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let self else {
                return
            }
            if let uuid = notification.object as? String, uuid == episode.uuid {
                if let newEpisode = DataManager.sharedManager.findBaseEpisode(uuid: uuid) {
                    episode = newEpisode
                }
            }
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.episodePlayStatusChanged)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let self else {
                return
            }
            if let uuid = notification.object as? String, uuid == episode.uuid {
                if let newEpisode = DataManager.sharedManager.findBaseEpisode(uuid: uuid) {
                    episode = newEpisode
                }
            }
        }
        .store(in: &cancellables)
    }

    private func updateProgress() {
        guard let currentEpisode = playbackManager.currentEpisode, episode.uuid == currentEpisode.uuid else {
            return
        }
        episode.playedUpTo = currentEpisode.playedUpTo
        episode.duration = currentEpisode.duration
        progress = calculateSafeProgress(from: currentEpisode)
    }

    private func calculateSafeProgress(from episode: BaseEpisode) -> Double {
        guard episode.duration > 0 else {
            return 0
        }
        if episode.played() {
            return 1
        }
        return min(1, episode.playedUpTo / episode.duration)
    }
}

/// Up Next queue actions shared by the episode view model and the lazily-loaded
/// discovery/search context menus, so the move-vs-add queue logic lives in one place.
enum EpisodeUpNextActions {
    static func playNext(_ episode: BaseEpisode, playbackManager: PlaybackManager = .shared) {
        if playbackManager.inUpNext(episode: episode) {
            playbackManager.queue.move(episode: episode, to: 0)
            Analytics.track(.upNextQueueReordered, properties: ["direction": "up", "is_next": true])
        } else {
            playbackManager.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
        }
        ToastManager.shared.show(L10n.tvEpisodeWillPlayNext)
    }

    static func playLast(_ episode: BaseEpisode, playbackManager: PlaybackManager = .shared) {
        if playbackManager.inUpNext(episode: episode) {
            let queueCount = playbackManager.queue.upNextCount()
            playbackManager.queue.move(episode: episode, to: max(queueCount - 1, 0))
            Analytics.track(.upNextQueueReordered, properties: ["direction": "down", "is_next": queueCount == 1])
        } else {
            playbackManager.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: false, userInitiated: true)
        }
        ToastManager.shared.show(L10n.tvEpisodeWillPlayLast)
    }
}

@Observable
class MockEpisodeRowViewModel: Identifiable {

    let episode: Episode
    let podcast: Podcast?

    init(episode: Episode, podcast: Podcast?) {
        self.episode = episode
        self.podcast = podcast
    }

    static func == (lhs: MockEpisodeRowViewModel, rhs: MockEpisodeRowViewModel) -> Bool {
        return lhs.episode.uuid == rhs.episode.uuid
    }

    var id: String { episode.uuid }

    var displayTitle: String {
        return episode.displayableTitle()
    }

    var displayDate: String {
        return episode.shortPublishedDate()
    }

    var displayDuration: String {
        return episode.duration.formatted()
    }
}
