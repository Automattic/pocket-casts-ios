import Foundation
import PocketCastsDataModel

public protocol ServerPlaybackDelegate {
    func playing() -> Bool
    func inUpNext(episode: BaseEpisode?) -> Bool
    func addToUpNext(episode: BaseEpisode, ignoringQueueLimit: Bool, toTop: Bool)
    func removeLastEpisodeFromUpNext()

    func currentEpisode() -> BaseEpisode?
    func isNowPlayingEpisode(episodeUuid: String?) -> Bool
    func isActivelyPlaying(episodeUuid: String?) -> Bool

    func queuePersistLocalCopyAsReplace()
    func queueRefreshList(checkForAutoDownload: Bool)
    func allEpisodesInQueue(includeNowPlaying: Bool) -> [BaseEpisode]
    func playingEpisodeChangedExternally()

    func upNextQueueChanged()
    func upNextQueueCount() -> Int

    func seekTo(time: TimeInterval, syncChanges: Bool, startPlaybackAfterSeek: Bool)
}
