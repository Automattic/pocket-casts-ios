import Combine
import Foundation
import PocketCastsDataModel
import SwiftUI

struct PlaySourceHelper {
    static var playSourceViewModel: PlaySourceViewModel {
        SourceManager.shared.isWatch() ? WatchSourceViewModel() : PhoneSourceViewModel()
    }
}

enum PlaySourceError: Error {
    case requestFailed
    case wrongBaseType
}

protocol PlaySourceViewModel {
    var isPlaying: Bool { get }

    // MARK: Episodes

    func fetchEpisode(uuid: String) -> BaseEpisode?
    func requiresConfirmation(forAction: EpisodeAction) -> Bool
    func isPlaying(forEpisode: BaseEpisode) -> Bool
    func inUpNext(forEpisode: BaseEpisode) -> Bool
    func isCurrentlyPlaying(episode: BaseEpisode) -> Bool
    func supportsPodcastNavigation(forEpisode: BaseEpisode) -> Bool

    // MARK: Playback

    var trimSilenceAvailable: Bool { get }
    var trimSilenceEnabled: Bool { get set }

    var volumeBoostAvailable: Bool { get }
    var volumeBoostEnabled: Bool { get set }

    func playPauseTapped(withEpisode episode: BaseEpisode, playlist: AutoplayHelper.Playlist?)
    func skip(forward: Bool)
    func changeChapter(next: Bool)

    var playbackSpeed: Double { get }
    func increasePlaybackSpeed()
    func decreasePlaybackSpeed()
    func changeSpeedInterval()

    // MARK: Episode Actions

    func downloaded(episode: BaseEpisode) -> Bool
    func download(episode: BaseEpisode)
    func pauseDownload(forEpisode: BaseEpisode)
    func deleteDownload(forEpisode: BaseEpisode)
    func removeFromUpNext(episode: BaseEpisode)
    func addToUpNext(episode: BaseEpisode, toTop: Bool)
    func archive(episode: BaseEpisode)
    func unarchive(episode: BaseEpisode)
    func setStarred(_ starred: Bool, episode: BaseEpisode)
    func markPlayed(episode: BaseEpisode)
    func markAsUnplayed(episode: BaseEpisode)

    // MARK: Downloads

    func fetchDownloadedEpisodes() -> AnyPublisher<[BaseEpisode], PlaySourceError>
    var downloadedCount: Int { get }

    // MARK: User Episodes

    var supportsFileSort: Bool { get }
    var userEpisodeSortOrder: UploadedSort { get set }
    func fetchUserEpisodes(forOrder: UploadedSort?) -> AnyPublisher<[BaseEpisode], PlaySourceError>

    // MARK: Filters

    func fetchFilters() -> AnyPublisher<[Filter], PlaySourceError>
    func fetchFilter(_ uuid: String) -> (any Filter)?
    func fetchFilterEpisodes(_ filter: any Filter) -> AnyPublisher<[BaseEpisode], PlaySourceError>
    func episodeCount(for filter: Filter) -> Int

    // MARK: Up Next

    var episodesInQueue: [BaseEpisode] { get }
    var episodeUuidsInQueue: [BaseEpisode] { get }
    func clearUpNext()

    // MARK: Now Playing

    var nowPlayingEpisode: BaseEpisode? { get }
    var playbackProgress: CGFloat { get }
    var effectsIconName: String { get }
    var upNextCount: Int { get }
    var playingEpisodeHasChapters: Bool { get }
    func nowPlayingTitle(forEpisode: BaseEpisode) -> String?
    func nowPlayingSubTitle(forEpisode: BaseEpisode) -> String?
    func nowPlayingTimeRemaining(forEpisode: BaseEpisode) -> String
    func nowPlayingTint(forEpisode: BaseEpisode) -> Color
}
