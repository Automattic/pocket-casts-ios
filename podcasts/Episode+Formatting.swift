import Foundation
import PocketCastsDataModel

extension Episode {
    func shortLastPlaybackInteractionDate() -> String {
        shortDateFor(date: lastPlaybackInteractionDate)
    }

    func shouldArchiveOnCompletion() -> Bool {
        #if !APPCLIP
        if let podcast = parentPodcast(), podcast.isAutoArchiveOverridden {
            return podcast.autoArchivePlayedAfterTime == 0 && (Settings.archiveStarredEpisodes() || !keepEpisode)
        }

        return Settings.autoArchivePlayedAfter() == 0 && (Settings.archiveStarredEpisodes() || !keepEpisode)
        #else
        return false
        #endif
    }

    func userHasInteractedWithEpisode() -> Bool {
        keepEpisode || archived || downloaded(pathFinder: DownloadManager.shared) || !unplayed() || PlaybackManager.shared.inUpNext(episode: self) || lastPlaybackInteractionDate != nil
    }

    func episodeCanBeCleanedUp() -> Bool {
        !keepEpisode &&
        !downloaded(pathFinder: DownloadManager.shared) &&
        !inProgress() &&
        !PlaybackManager.shared.inUpNext(episode: self) &&
        !DataManager.sharedManager.playlistContainsEpisode(episodeUuid: uuid)
    }

    public func subTitle() -> String {
        parentPodcast()?.title ?? ""
    }
}
