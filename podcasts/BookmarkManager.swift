import Foundation
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarkManager {
    private let dataManager = DataManager.sharedManager.bookmarks
    /// How long a bookmark clip is
    /// TODO: Make configurable
    private let clipLength = 1.minute

    /// Adds a new bookmark for an episode at the given time
    func add(to episode: BaseEpisode, at time: TimeInterval) {
        // If the episode has a podcast attached, also save that
        let podcastUuid: String? = (episode as? Episode)?.podcastUuid

        // If someone is bookmarking a point in time, they probably want to remember the info leading up to the bookmark
        // time, so calculate the start of the clip as X seconds before the bookmark time
        let startTime = max(0, time - clipLength)

        dataManager.add(episodeUuid: episode.uuid, podcastUuid: podcastUuid, start: startTime, end: time)


        FileLog.shared.addMessage("[Bookmarks] Added bookmark for \(episode.displayableTitle()) from \(startTime) to \(time)")
    }

    /// Retrieves all the bookmarks for a episode
    func bookmarks(for episode: BaseEpisode) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: episode.uuid)
    }

    /// Retrieves all the bookmarks for a podcast
    func bookmarks(for podcast: Podcast) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: podcast.uuid)
    }
}

