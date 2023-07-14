import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import Combine

class BookmarkManager {
    private let dataManager: BookmarkDataManager

    // Publishers
    let onBookmarkCreated = PassthroughSubject<(BaseEpisode, Bookmark), Never>()
    let onBookmarksDeleted = PassthroughSubject<([Bookmark]), Never>()

    init(dataManager: BookmarkDataManager = DataManager.sharedManager.bookmarks) {
        self.dataManager = dataManager
    }

    /// Plays the "bookmark created" tone
    private lazy var tonePlayer: AVAudioPlayer? = {
        guard
            let url = Bundle.main.url(forResource: "TODO", withExtension: "TODO"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else {
            return nil
        }

        player.prepareToPlay()
        return player
    }()

    /// Adds a new bookmark for an episode at the given time
    func add(to episode: BaseEpisode, at time: TimeInterval, title: String = L10n.bookmarkDefaultTitle) {
        // If the episode has a podcast attached, also save that
        let podcastUuid: String? = (episode as? Episode)?.podcastUuid

        let uuid = dataManager.add(episodeUuid: episode.uuid, podcastUuid: podcastUuid, title: title, time: time)

        // Inform the subscribers a bookmark was added
        uuid.flatMap { dataManager.bookmark(for: $0) }.map {
            onBookmarkCreated.send((episode, $0))
        }

        FileLog.shared.addMessage("[Bookmarks] Added bookmark for \(episode.displayableTitle()) at \(time)")
    }

    /// Retrieves all the bookmarks for a episode
    func bookmarks(for episode: BaseEpisode) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: episode.uuid)
    }

    /// Retrieves all the bookmarks for a podcast
    func bookmarks(for podcast: Podcast) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: podcast.uuid)
    }

    /// Removes an array of bookmarks
    func remove(_ bookmarks: [Bookmark]) async -> Bool {
        let success = await dataManager.remove(bookmarks: bookmarks)

        // Inform any listeners
        if success {
            onBookmarksDeleted.send(bookmarks)
        }

        return success
    }
}

// MARK: - Confirmation Tone Playing

extension BookmarkManager {
    func playTone() {
        // Stop playing immediately and reset to 0
        tonePlayer?.pause()
        tonePlayer?.currentTime = 0

        // Play
        tonePlayer?.play()
    }
}
