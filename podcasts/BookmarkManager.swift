import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import Combine

class BookmarkManager {
    private let dataManager: BookmarkDataManager
    private let generalManager: DataManager
    private let playbackManager: PlaybackManager

    /// Called when a bookmark is created
    let onBookmarkCreated = PassthroughSubject<Event.Created, Never>()

    /// Called when one or more bookmarks are deleted
    let onBookmarksDeleted = PassthroughSubject<Event.Deleted, Never>()

    /// Called when a value of the bookmark changes
    let onBookmarkChanged = PassthroughSubject<Event.Changed, Never>()

    init(dataManager: BookmarkDataManager = DataManager.sharedManager.bookmarks,
         generalManager: DataManager = .sharedManager,
         playbackManager: PlaybackManager = .shared) {
        self.dataManager = dataManager
        self.generalManager = generalManager
        self.playbackManager = playbackManager
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
    @discardableResult
    func add(to episode: BaseEpisode, at time: TimeInterval, title: String = L10n.bookmarkDefaultTitle) -> Bookmark? {
        // If the episode has a podcast attached, also save that
        let podcastUuid: String? = (episode as? Episode)?.podcastUuid

        return dataManager.add(episodeUuid: episode.uuid, podcastUuid: podcastUuid, title: title, time: time).flatMap {
            FileLog.shared.addMessage("[Bookmarks] Added bookmark for \(episode.displayableTitle()) at \(time)")

            // Inform the subscribers a bookmark was added
            onBookmarkCreated.send(.init(uuid: $0, episode: episode.uuid, podcast: podcastUuid))

            return dataManager.bookmark(for: $0)
        }
    }

    /// Returns an existing bookmark with the given `uuid`
    func bookmark(for uuid: String) -> Bookmark? {
        dataManager.bookmark(for: uuid)
    }

    /// Retrieves all the bookmarks for a episode
    func bookmarks(for episode: BaseEpisode, sorted: BookmarkSortOption = .newestToOldest) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: episode.uuid, sorted: sorted.dataSortOption)
    }

    /// Retrieves all the bookmarks for a podcast
    func bookmarks(for podcast: Podcast, sorted: BookmarkSortOption = .newestToOldest) -> [Bookmark] {
        dataManager.bookmarks(forPodcast: podcast.uuid, sorted: sorted.dataSortOption)
    }

    /// Removes an array of bookmarks
    func remove(_ bookmarks: [Bookmark]) async -> Bool {
        await dataManager.remove(bookmarks: bookmarks).when(true) {
            onBookmarksDeleted.send(.init(uuids: bookmarks.map(\.uuid)))
        }
    }

    /// Updates the bookmark with the given title, emits `onBookmarkChanged` on success
    @discardableResult
    func update(title: String, for bookmark: Bookmark) async -> Bool {
        await dataManager.update(title: title, for: bookmark).when(true) {
            onBookmarkChanged.send(.init(uuid: bookmark.uuid, change: .title(title)))
        }
    }

    // MARK: - Playback

    /// Play the bookmark
    func play(_ bookmark: Bookmark) {
        // If we're already the now playing episode, then just seek to the bookmark time
        if playbackManager.isNowPlayingEpisode(episodeUuid: bookmark.episodeUuid) {
            playbackManager.seekTo(time: bookmark.time, startPlaybackAfterSeek: true)
            return
        }

        // Get the bookmark's BaseEpisode so we can load it
        guard let episode = bookmark.episode ?? generalManager.findBaseEpisode(uuid: bookmark.episodeUuid) else {
            return
        }

        #if !os(watchOS)
        // Save the playback time before we start playing so the player will jump to the correct starting time when it does load
        generalManager.saveEpisode(playedUpTo: bookmark.time, episode: episode, updateSyncFlag: false)

        // Start the play process
        PlaybackActionHelper.play(episode: episode, podcastUuid: bookmark.podcastUuid)
        #endif
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

// MARK: - BookmarkSortOption

private extension BookmarkSortOption {
    var dataSortOption: BookmarkDataManager.SortOption {
        switch self {
        case .newestToOldest:
            return .newestToOldest
        case .oldestToNewest:
            return .oldestToNewest
        case .timestamp:
            return .timestamp
        }
    }
}


// MARK: - Bookmarks Array Extension

extension Array where Element == Bookmark {
    /// Updates an array of Bookmarks and sets the `episode` property to the `BaseEpisode` from the `episodeUuid`
    /// This tries to be efficient by only fetching the unique episodes from the database
    func includeEpisodes(using dataManager: DataManager = .sharedManager) -> [Element] {
        guard count > 0 else { return [] }

        let episodes = uniqueEpisodes(using: dataManager)

        return map {
            var item = $0
            item.episode = episodes[item.episodeUuid]
            return item
        }
    }

    /// Gets the unique episodeUuid's from the bookmarks, then converts them to `BaseEpisode`'s
    /// which are then mapped to a dictionary where the key is the episodeUuid and the value is the episode
    private func uniqueEpisodes(using dataManager: DataManager = .sharedManager) -> [String: BaseEpisode] {
        Dictionary(uniqueKeysWithValues: Set(map(\.episodeUuid)).compactMap {
            dataManager.findBaseEpisode(uuid: $0)
        }.map { ($0.uuid, $0) })
    }
}
