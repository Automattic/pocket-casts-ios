import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

class WatchSourceViewModel: PlaySourceViewModel {
    var isPlaying: Bool {
        PlaybackManager.shared.playing()
    }

    // MARK: Episodes

    func fetchEpisode(uuid: String) -> BaseEpisode? {
        DataManager.sharedManager.findBaseEpisode(uuid: uuid)
    }

    func requiresConfirmation(forAction action: EpisodeAction) -> Bool {
        switch action {
        case .deleteDownload:
            return true
        default:
            return false
        }
    }

    func isPlaying(forEpisode episode: BaseEpisode) -> Bool {
        PlaybackManager.shared.isActivelyPlaying(episodeUuid: episode.uuid)
    }

    func inUpNext(forEpisode episode: BaseEpisode) -> Bool {
        PlaybackManager.shared.inUpNext(episode: episode)
    }

    func isCurrentlyPlaying(episode: BaseEpisode) -> Bool {
        PlaybackManager.shared.currentEpisode()?.uuid == episode.uuid
    }

    func supportsPodcastNavigation(forEpisode episode: BaseEpisode) -> Bool {
        (episode as? Episode)?.parentPodcast() != nil
    }

    // MARK: Playback

    let trimSilenceAvailable: Bool = false
    var trimSilenceEnabled: Bool {
        get { false }
        set {} // This is intentionally a noop because this feature isn't supported on the Watch
    }

    let volumeBoostAvailable: Bool = false
    var volumeBoostEnabled: Bool {
        get { false }
        set {} // This is intentionally a noop because this feature isn't supported on the Watch
    }

    func playPauseTapped(withEpisode episode: BaseEpisode, playlist: AutoplayHelper.Playlist?) {
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            PlaybackManager.shared.playPause()
        } else {
            PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
        }
    }

    func skip(forward: Bool) {
        if forward {
            PlaybackManager.shared.skipForward()
        } else {
            PlaybackManager.shared.skipBack()
        }
    }

    func changeChapter(next: Bool) {
        if next {
            PlaybackManager.shared.skipToNextChapter()
        } else {
            PlaybackManager.shared.skipToPreviousChapter()
        }
    }

    var playbackSpeed: Double {
        PlaybackManager.shared.effects().playbackSpeed
    }

    func increasePlaybackSpeed() {
        PlaybackManager.shared.increasePlaybackSpeed()
    }

    func decreasePlaybackSpeed() {
        PlaybackManager.shared.decreasePlaybackSpeed()
    }

    func changeSpeedInterval() {
        let effects = PlaybackManager.shared.effects()
        effects.toggleDefinedSpeedInterval()

        PlaybackManager.shared.changeEffects(effects)
    }

    // MARK: Episode Actions

    func downloaded(episode: BaseEpisode) -> Bool {
        episode.downloaded(pathFinder: DownloadManager.shared)
    }

    func download(episode: BaseEpisode) {
        DownloadManager.shared.addToQueue(episodeUuid: episode.uuid)
    }

    func pauseDownload(forEpisode episode: BaseEpisode) {
        DownloadManager.shared.removeFromQueue(episode: episode, fireNotification: true, userInitiated: true)
    }

    func deleteDownload(forEpisode episode: BaseEpisode) {
        if let userEpisode = episode as? UserEpisode {
            UserEpisodeManager.deleteFromDevice(userEpisode: userEpisode)
        } else {
            EpisodeManager.deleteDownloadedFiles(episode: episode)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
        }
    }

    func removeFromUpNext(episode: BaseEpisode) {
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: true)
    }

    func addToUpNext(episode: BaseEpisode, toTop: Bool) {
        PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: false)
        PlaybackManager.shared.addToUpNext(episode: episode, ignoringQueueLimit: true, toTop: toTop)
    }

    func archive(episode: BaseEpisode) {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
    }

    func unarchive(episode: BaseEpisode) {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.unarchiveEpisode(episode: episode, fireNotification: true)
    }

    func setStarred(_ starred: Bool, episode: BaseEpisode) {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.setStarred(starred, episode: episode, updateSyncStatus: true)
    }

    func markPlayed(episode: BaseEpisode) {
        EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
    }

    func markAsUnplayed(episode: BaseEpisode) {
        EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
    }

    // MARK: Downloads

    func fetchDownloadedEpisodes() -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        let fetchedEpisodes = DataManager.sharedManager.findDownloadedEpisodes()
        return Just(fetchedEpisodes).setFailureType(to: PlaySourceError.self).eraseToAnyPublisher()
    }

    var downloadedCount: Int {
        return DataManager.sharedManager.downloadedEpisodeCount()
    }

    // MARK: User Episodes

    var supportsFileSort = true
    var userEpisodeSortOrder: UploadedSort {
        get {
            UploadedSort(rawValue: Settings.userEpisodeSortBy()) ?? UploadedSort.newestToOldest
        }
        set {
            Settings.setUserEpisodeSortBy(newValue.rawValue)
        }
    }

    func fetchUserEpisodes(forOrder sortingOption: UploadedSort? = nil) -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        let sortOrder = sortingOption ?? userEpisodeSortOrder
        let fetchedEpisodes = DataManager.sharedManager.allUserEpisodes(sortedBy: sortOrder, limit: Constants.Limits.watchListItems)
        return Just(fetchedEpisodes).setFailureType(to: PlaySourceError.self).eraseToAnyPublisher()
    }

    // MARK: Filters

    internal func fetchFilterEpisodes(_ filter: Filter) -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        guard let filter = filter as? EpisodeFilter else {
            /// Watch Source should be communicating using `EpisodeFilter`. This is likely a developer error.
            return Fail<[BaseEpisode], PlaySourceError>(error: .wrongBaseType).eraseToAnyPublisher()
        }

        return fetchFilterEpisodes(filter)
    }

    func fetchFilterEpisodes(_ filter: EpisodeFilter) -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Constants.Limits.watchListItems)
        let filterEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: nil)
        return Just(filterEpisodes).setFailureType(to: PlaySourceError.self).eraseToAnyPublisher()
    }

    func fetchFilters() -> AnyPublisher<[Filter], PlaySourceError> {
        let filters = DataManager.sharedManager.allFilters(includeDeleted: false)
        return Just(filters).setFailureType(to: PlaySourceError.self).eraseToAnyPublisher()
    }

    func fetchFilter(_ uuid: String) -> Filter? {
        DataManager.sharedManager.findFilter(uuid: uuid)
    }

    func episodeCount(for filter: Filter) -> Int {
        guard let episodeFilter = filter as? EpisodeFilter else {
            return 0
        }
        return DataManager.sharedManager.episodeCount(forFilter: episodeFilter, episodeUuidToAdd: episodeFilter.episodeUuidToAddToQueries())
    }

    // MARK: Up Next

    var episodesInQueue: [BaseEpisode] {
        PlaybackManager.shared.allEpisodesInQueue(includeNowPlaying: false)
    }

    var episodeUuidsInQueue: [BaseEpisode] {
        PlaybackManager.shared.allEpisodeUuidsInQueue()
    }

    func clearUpNext() {
        PlaybackManager.shared.queue.clearUpNextList()
    }

    // MARK: Now Playing

    var nowPlayingEpisode: BaseEpisode? {
        PlaybackManager.shared.currentEpisode()
    }

    var playbackProgress: CGFloat {
        let currentTime = PlaybackManager.shared.currentTime()
        let duration = PlaybackManager.shared.duration()

        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var effectsIconName: String {
        PlaybackManager.shared.effects().effectsEnabled() ? "speed-on" : "speed-off"
    }

    var upNextCount: Int {
        PlaybackManager.shared.queue.upNextCount()
    }

    var playingEpisodeHasChapters: Bool {
        PlaybackManager.shared.chapterCount() > 0
    }

    func nowPlayingTitle(forEpisode episode: BaseEpisode) -> String? {
        let chapters = PlaybackManager.shared.currentChapters()
        guard
            let chapter = chapters.visibleChapter,
            PlaybackManager.shared.chapterCount() != 0,
            !chapters.title.isEmpty
        else {
            return episode.displayableTitle()
        }

        return chapter.title
    }

    func nowPlayingSubTitle(forEpisode episode: BaseEpisode) -> String? {
        guard !PlaybackManager.shared.buffering() else { return L10n.watchBuffering }
        return episode.subTitle()
    }

    func nowPlayingTimeRemaining(forEpisode episode: BaseEpisode) -> String {
        let timeRemaining = max(0, PlaybackManager.shared.duration() - PlaybackManager.shared.currentTime())
        return TimeFormatter.shared.playTimeFormat(time: timeRemaining, showSeconds: true)
    }

    func nowPlayingTint(forEpisode episode: BaseEpisode) -> Color {
        episode.subTitleColor
    }

    // MARK: Podcasts

    var podcastSortOrder: LibrarySort {
        get {
            Settings.homeFolderSortOrder()
        }
        set {
            Settings.setHomeFolderSortOrder(order: newValue)
        }
    }

    func allHomeGridItemsSorted(sortedBy: LibrarySort) -> [HomeGridItem] {
        HomeGridDataHelper.gridItems(orderedBy: sortedBy)
    }

    func allPodcastsInFolder(folder: Folder) -> [Podcast] {
        DataManager.sharedManager.allPodcastsInFolder(folder: folder)
    }
}
