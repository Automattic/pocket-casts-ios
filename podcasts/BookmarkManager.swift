import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import Combine

class BookmarkManager {
    private let dataManager: BookmarkDataManager

    static let defaultTitle = L10n.bookmarkDefaultTitle

    /// Called when a bookmark is created
    let onBookmarkCreated = PassthroughSubject<Event.Created, Never>()

    /// Called when one or more bookmarks are deleted
    let onBookmarksDeleted = PassthroughSubject<Event.Deleted, Never>()

    /// Called when a value of the bookmark changes
    let onBookmarkChanged = PassthroughSubject<Event.Changed, Never>()

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
    /// Updates the bookmark with the given title, emits `onBookmarkChanged` on success
    @discardableResult
    func update(title: String, for bookmark: Bookmark) async -> Bool {
        await dataManager.update(title: title, for: bookmark).when(true) {
            onBookmarkChanged.send(.init(uuid: bookmark.uuid, change: .title(title)))
        }
    }

    // MARK: - Named Events

    enum Event {
        struct Created {
            /// The uuid of the newly created bookmark
            let uuid: String

            /// The uuid of the episode the bookmark was added to
            let episode: String

            /// The uuid of the podcast the bookmark was added to, if available
            let podcast: String?
        }

        struct Changed {
            /// The uuid of the changed bookmark
            let uuid: String

            /// The type of change
            let change: Change

            enum Change {
                /// The title of the bookmark was changed
                /// The new value is passed as a value
                case title(String)
            }
        }

        struct Deleted {
            let uuids: [String]
        }
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
