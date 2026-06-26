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

    /// The analytics `source` for actions taken on this row, set by the screen that
    /// builds it (Podcast, Up Next, Starred, …). This is the tvOS equivalent of iOS's
    /// per-screen `AnalyticsSourceProvider`: actions push it onto the shared analytics
    /// helpers so the events `EpisodeManager`/`PlaybackManager` fire carry the source.
    let analyticsSource: AnalyticsSource

    private var cancellables: Set<AnyCancellable> = []
    private let playbackManager: PlaybackManager

    init(episode: BaseEpisode, podcast: Podcast?, analyticsSource: AnalyticsSource = .unknown, playbackManager: PlaybackManager = PlaybackManager.shared) {
        self.episode = episode
        self.podcast = podcast
        self.analyticsSource = analyticsSource
        self.playbackManager = playbackManager
        self.progress = episode.playedUpTo / episode.duration
        setupObservers()
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

    func play() {
        guard !playbackManager.isActivelyPlaying(episodeUuid: episode.uuid) else { return }
        PlaybackActionHelper.play(episode: episode, podcastUuid: podcastUuid)
    }

    func playNext() {
        EpisodeUpNextActions.playNext(episode, source: analyticsSource, playbackManager: playbackManager)
    }

    func playLast() {
        EpisodeUpNextActions.playLast(episode, source: analyticsSource, playbackManager: playbackManager)
    }

    func markAsPlayed() {
        AnalyticsEpisodeHelper.shared.currentSource = analyticsSource
        EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeMarkedAsPlayed)
    }

    var canArchive: Bool {
        episode is Episode
    }

    var isArchived: Bool {
        (episode as? Episode)?.archived ?? false
    }

    var isVideo: Bool {
        episode.videoPodcast()
    }

    func archive() {
        guard let episode = episode as? Episode else { return }
        AnalyticsEpisodeHelper.shared.currentSource = analyticsSource
        EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeArchived)
    }

    func unarchive() {
        guard let episode = episode as? Episode else { return }
        AnalyticsEpisodeHelper.shared.currentSource = analyticsSource
        EpisodeManager.unarchiveEpisode(episode: episode, fireNotification: true)
        ToastManager.shared.show(L10n.tvEpisodeUnarchived)
    }

    func removeFromUpNext() {
        AnalyticsEpisodeHelper.shared.currentSource = analyticsSource
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
    }

    private func updateProgress() {
        guard let currentEpisode = playbackManager.currentEpisode(), episode.uuid == currentEpisode.uuid else {
            return
        }
        episode.playedUpTo = currentEpisode.playedUpTo
        episode.duration = currentEpisode.duration
        progress = currentEpisode.playedUpTo / currentEpisode.duration
    }
}

/// Up Next queue actions shared by the episode view model and the lazily-loaded
/// discovery/search context menus, so the move-vs-add queue logic lives in one place.
enum EpisodeUpNextActions {
    static func playNext(_ episode: BaseEpisode, source: AnalyticsSource = .unknown, playbackManager: PlaybackManager = .shared) {
        if playbackManager.inUpNext(episode: episode) {
            playbackManager.queue.move(episode: episode, to: 0)
            Analytics.track(.upNextQueueReordered, properties: ["direction": "up", "is_next": true, "source": source])
        } else {
            // `addToUpNext` fires `episodeAddedToUpNext` through the shared helper, which
            // consumes `currentSource`; set it only on this branch so it can't leak into a
            // later event when we just reorder an episode that's already queued.
            AnalyticsEpisodeHelper.shared.currentSource = source
            playbackManager.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
        }
        ToastManager.shared.show(L10n.tvEpisodeWillPlayNext)
    }

    static func playLast(_ episode: BaseEpisode, source: AnalyticsSource = .unknown, playbackManager: PlaybackManager = .shared) {
        if playbackManager.inUpNext(episode: episode) {
            let queueCount = playbackManager.queue.upNextCount()
            playbackManager.queue.move(episode: episode, to: max(queueCount - 1, 0))
            Analytics.track(.upNextQueueReordered, properties: ["direction": "down", "is_next": queueCount == 1, "source": source])
        } else {
            AnalyticsEpisodeHelper.shared.currentSource = source
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
