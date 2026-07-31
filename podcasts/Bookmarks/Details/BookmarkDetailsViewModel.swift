import Foundation
import PocketCastsDataModel
import PocketCastsServer

/// What the bookmark details show, kept in one place so the hosting controller can
/// refresh it after the bookmark is edited.
@MainActor
class BookmarkDetailsViewModel: ObservableObject {
    @Published private(set) var bookmark: Bookmark

    /// The captured transcript passage, absent for bookmarks made before it was captured
    @Published private(set) var passage: String?

    /// Fetched from the server when the podcast isn't in the local database, e.g. a
    /// bookmark synced from a podcast this device isn't subscribed to
    @Published private(set) var podcastTitle: String?

    @Published private(set) var isLoadingPodcastTitle = false

    let episode: BaseEpisode?

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
                  passage: bookmark.passage,
                  episode: episode,
                  podcastTitle: Self.localPodcastTitle(for: bookmark, episode: episode),
                  bookmarkManager: bookmarkManager)

        if podcastTitle == nil {
            loadPodcastTitle()
        }
    }

    func refresh() {
        guard let bookmark = bookmarkManager.bookmark(for: bookmark.uuid) else { return }

        self.bookmark = bookmark
        self.passage = bookmark.passage
    }

    private func loadPodcastTitle() {
        guard let podcastUuid = Self.podcastUuid(for: bookmark, episode: episode) else { return }

        isLoadingPodcastTitle = true

        CacheServerHandler.shared.loadPodcastInfo(podcastUuid: podcastUuid) { podcastInfo, _ in
            let title = (podcastInfo?["podcast"] as? [String: Any])?["title"] as? String

            Task { @MainActor [weak self] in
                self?.podcastTitle = title
                self?.isLoadingPodcastTitle = false
            }
        }
    }

    private static func localPodcastTitle(for bookmark: Bookmark, episode: BaseEpisode?) -> String? {
        podcastUuid(for: bookmark, episode: episode)
            .flatMap { DataManager.sharedManager.findPodcast(uuid: $0, includeUnsubscribed: true)?.title }
    }

    private static func podcastUuid(for bookmark: Bookmark, episode: BaseEpisode?) -> String? {
        bookmark.podcastUuid ?? (episode as? Episode)?.podcastUuid
    }
}
