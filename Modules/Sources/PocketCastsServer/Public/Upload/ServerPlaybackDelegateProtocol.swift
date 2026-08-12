import Foundation
import PocketCastsDataModel

public protocol ServerPlaybackDelegate {
    var isPlaying: Bool { get }
    func inUpNext(episode: BaseEpisode?) -> Bool
    func addToUpNext(episode: BaseEpisode, ignoringQueueLimit: Bool, toTop: Bool)
    func removeLastEpisodeFromUpNext()

    var currentEpisode: BaseEpisode? { get }
    func isCurrentEpisode(uuid: String) -> Bool
    func isActivelyPlaying(episodeUuid: String) -> Bool

    func queuePersistLocalCopyAsReplace()
    func queueRefreshList(checkForAutoDownload: Bool)
    func allEpisodesInQueue(includeNowPlaying: Bool) -> [BaseEpisode]
    func playingEpisodeChangedExternally()

    func upNextQueueChanged()
    func upNextQueueCount() -> Int

    func seekToFromSync(time: TimeInterval, syncChanges: Bool, startPlaybackAfterSeek: Bool)
}
