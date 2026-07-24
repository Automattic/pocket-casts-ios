import Foundation
import PocketCastsDataModel

/// What the bookmark details show, kept in one place so the hosting controller can
/// refresh it after the bookmark is edited.
@MainActor
class BookmarkDetailsViewModel: ObservableObject {
    @Published private(set) var bookmark: Bookmark

    /// The captured transcript passage, absent for bookmarks made before it was captured
    @Published private(set) var passage: String?

    let episode: BaseEpisode?
    let podcastTitle: String?

    /// Assigned by the hosting controller, which owns playback
    var onPlay: () -> Void = {}

    private let bookmarkManager: BookmarkManager

    init(bookmark: Bookmark,
         passage: String?,
         episode: BaseEpisode?,
         podcastTitle: String?,
         bookmarkManager: BookmarkManager = PlaybackManager.shared.bookmarkManager) {
        self.bookmark = bookmark
        self.passage = passage
        self.episode = episode
        self.podcastTitle = podcastTitle
        self.bookmarkManager = bookmarkManager
    }

    convenience init(bookmark: Bookmark, bookmarkManager: BookmarkManager) {
        let episode = bookmark.episode ?? bookmarkManager.episode(for: bookmark)

        self.init(bookmark: bookmark,
                  passage: bookmarkManager.passage(for: bookmark),
                  episode: episode,
                  podcastTitle: Self.podcastTitle(for: bookmark, episode: episode),
                  bookmarkManager: bookmarkManager)
    }

    func refresh() {
        guard let bookmark = bookmarkManager.bookmark(for: bookmark.uuid) else { return }

        self.bookmark = bookmark
        self.passage = bookmarkManager.passage(for: bookmark)
    }

    private static func podcastTitle(for bookmark: Bookmark, episode: BaseEpisode?) -> String? {
        let uuid = bookmark.podcastUuid ?? (episode as? Episode)?.podcastUuid
        return uuid.flatMap { DataManager.sharedManager.findPodcast(uuid: $0)?.title }
    }
}
