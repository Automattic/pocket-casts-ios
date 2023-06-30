import Combine
import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

class PhoneSourceViewModel: PlaySourceViewModel {
    var isPlaying: Bool {
        WatchDataManager.isPlaying()
    }

    // MARK: Episodes

    func fetchEpisode(uuid: String) -> BaseEpisode? {
        WatchDataManager.episodeIfAvailable(uuid: uuid)
    }

    func requiresConfirmation(forAction: EpisodeAction) -> Bool {
        false
    }

    func isPlaying(forEpisode episode: BaseEpisode) -> Bool {
        WatchDataManager.playingEpisode()?.uuid == episode.uuid && WatchDataManager.isPlaying()
    }

    func inUpNext(forEpisode episode: BaseEpisode) -> Bool {
        let upNextEpisodes = WatchDataManager.upNextEpisodes()
        return isCurrentlyPlaying(episode: episode) || ((upNextEpisodes?.filter { $0.uuid == episode.uuid }.count ?? 0) > 0)
    }

    func isCurrentlyPlaying(episode: BaseEpisode) -> Bool {
        let playingEpisode = WatchDataManager.playingEpisode()
        return (playingEpisode?.uuid == episode.uuid)
    }

    func supportsPodcastNavigation(forEpisode: BaseEpisode) -> Bool {
        false
    }

    // MARK: Playback

    let trimSilenceAvailable: Bool = true
    var trimSilenceEnabled: Bool {
        get {
            WatchDataManager.trimSilenceEnabled()
        }
        set {
            SessionManager.shared.setTrimSilence(enabled: newValue)
        }
    }

    let volumeBoostAvailable: Bool = true
    var volumeBoostEnabled: Bool {
        get {
            WatchDataManager.volumeBoostEnabled()
        }
        set {
            SessionManager.shared.setVolumeBoost(enabled: newValue)
        }
    }

    func playPauseTapped(withEpisode episode: BaseEpisode, playlist: AutoplayHelper.Playlist?) {
        if let currentEpisode = WatchDataManager.playingEpisode(), currentEpisode.uuid == episode.uuid {
            SessionManager.shared.togglePlayPause()
        } else {
            SessionManager.shared.play(episode: episode, playlist: playlist)
        }
    }

    func skip(forward: Bool) {
        if forward {
            SessionManager.shared.skipForward()
        } else {
            SessionManager.shared.skipBack()
        }
    }

    func changeChapter(next: Bool) {
        SessionManager.shared.changeChapter(next: next)
    }

    var playbackSpeed: Double {
        WatchDataManager.playbackSpeed()
    }

    func increasePlaybackSpeed() {
        SessionManager.shared.increasePlaybackSpeed()
    }

    func decreasePlaybackSpeed() {
        SessionManager.shared.decreasePlaybackSpeed()
    }

    func changeSpeedInterval() {
        SessionManager.shared.changeSpeedInterval()
    }

    // MARK: Episode Actions

    func downloaded(episode: BaseEpisode) -> Bool {
        episode.episodeStatus == DownloadStatus.downloaded.rawValue
    }

    func download(episode: BaseEpisode) {
        SessionManager.shared.downloadEpisode(episodeUuid: episode.uuid)
    }

    func pauseDownload(forEpisode episode: BaseEpisode) {
        SessionManager.shared.stopEpisodeDownload(episodeUuid: episode.uuid)
    }

    func deleteDownload(forEpisode episode: BaseEpisode) {
        SessionManager.shared.deleteDownload(episodeUuid: episode.uuid)
    }

    func removeFromUpNext(episode: BaseEpisode) {
        SessionManager.shared.removeFromUpNext(episodeUuid: episode.uuid)
    }

    func addToUpNext(episode: BaseEpisode, toTop: Bool) {
        SessionManager.shared.addToUpNext(episodeUuid: episode.uuid, toTop: toTop)
    }

    func archive(episode: BaseEpisode) {
        SessionManager.shared.archiveEpisode(episodeUuid: episode.uuid)
    }

    func unarchive(episode: BaseEpisode) {
        SessionManager.shared.unarchiveEpisode(episodeUuid: episode.uuid)
    }

    func setStarred(_ starred: Bool, episode: BaseEpisode) {
        guard let episode = episode as? Episode else { return }
        SessionManager.shared.setEpisodeStarred(starred: starred, episodeUuid: episode.uuid)
    }

    func markPlayed(episode: BaseEpisode) {
        SessionManager.shared.markPlayed(episodeUuid: episode.uuid)
    }

    func markAsUnplayed(episode: BaseEpisode) {
        SessionManager.shared.markUnplayed(episodeUuid: episode.uuid)
    }

    // MARK: Downloads

    func fetchDownloadedEpisodes() -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        Future { promise in
            SessionManager.shared.requestDownloadedEpisodes(replyHandler: { episodes in
                promise(.success(episodes))
            }, errorHandler: {
                promise(.failure(.requestFailed))
            })
        }
        .eraseToAnyPublisher()
    }

    // MARK: User Episodes

    var supportsFileSort = false
    var userEpisodeSortOrder: UploadedSort = .newestToOldest
    func fetchUserEpisodes(forOrder sortingOption: UploadedSort?) -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        Future { promise in
            SessionManager.shared.requestUserEpisodes(replyHandler: { episodes in
                promise(.success(episodes))
            }, errorHandler: {
                promise(.failure(.requestFailed))
            })
        }
        .eraseToAnyPublisher()
    }

    // MARK: Filters

    func fetchFilter(_ uuid: String) -> Filter? {
        WatchDataManager.filters()?.first(where: { $0.uuid == uuid })
    }

    internal func fetchFilterEpisodes(_ filter: Filter) -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        guard let filter = filter as? WatchFilter else {
            /// Play Source should be communicating using `WatchFilter`. This is likely a developer error.
            return Fail<[BaseEpisode], PlaySourceError>(error: .wrongBaseType).eraseToAnyPublisher()
        }

        return fetchFilterEpisodes(filter)
    }

    func fetchFilterEpisodes(_ filter: WatchFilter) -> AnyPublisher<[BaseEpisode], PlaySourceError> {
        Future { promise in
            SessionManager.shared.requestContents(filter: filter, replyHandler: { episodes in
                promise(.success(episodes))
            }, errorHandler: {
                promise(.failure(.requestFailed))
            })
        }
        .eraseToAnyPublisher()
    }

    // MARK: Up Next

    var episodesInQueue: [BaseEpisode] {
        WatchDataManager.upNextEpisodes() ?? []
    }

    func clearUpNext() {
        SessionManager.shared.clearUpNext()
    }

    // MARK: Now Playing

    var nowPlayingEpisode: BaseEpisode? {
        WatchDataManager.playingEpisode()
    }

    var playbackProgress: CGFloat {
        let currentTime = WatchDataManager.currentTime()
        let duration = WatchDataManager.duration()

        guard duration > 0 else { return 0 }

        return currentTime / duration
    }

    var effectsIconName: String {
        let effectsEnabled = WatchDataManager.trimSilenceEnabled() || WatchDataManager.volumeBoostEnabled() || WatchDataManager.playbackSpeed() != 1
        return effectsEnabled ? "effects-on" : "effects-off"
    }

    var upNextCount: Int {
        WatchDataManager.upNextCount()
    }

    var playingEpisodeHasChapters: Bool {
        WatchDataManager.playingEpisodeHasChapters()
    }

    func nowPlayingTitle(forEpisode episode: BaseEpisode) -> String? {
        let chapterTitle = WatchDataManager.nowPlayingChapterTitle()
        return chapterTitle.count > 0 ? chapterTitle : episode.title
    }

    func nowPlayingSubTitle(forEpisode episode: BaseEpisode) -> String? {
        WatchDataManager.nowPlayingSubTitle()
    }

    func nowPlayingTimeRemaining(forEpisode episode: BaseEpisode) -> String {
        let duration = WatchDataManager.duration()
        let currentTime = WatchDataManager.currentTime()

        guard duration > 0 else { return "" }

        let timeRemaining = duration - currentTime
        return TimeFormatter.shared.playTimeFormat(time: timeRemaining, showSeconds: false)
    }

    func nowPlayingTint(forEpisode: BaseEpisode) -> Color {
        guard let uiColor = WatchDataManager.nowPlayingColor() else {
            return .white
        }
        return Color(uiColor)
    }
}
