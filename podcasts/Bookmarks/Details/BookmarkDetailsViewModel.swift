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

    /// The full episode transcript with the passage located in it, so the passage can be
    /// shown in place. Fetched by `loadTranscript`; nil while loading or when the
    /// transcript isn't available, leaving the passage to stand alone.
    @Published private(set) var transcriptSnippet: BookmarkTranscriptSnippet?

    /// Whether the transcript is still being fetched, so a placeholder can stand in for
    /// it until it arrives. Already true where a fetch is coming, so the placeholder is
    /// what the screen opens on.
    @Published private(set) var isLoadingTranscript: Bool

    /// Whether the transcript took long enough to be worth fading the placeholder out
    /// for. One that's already to hand arrives before the placeholder has really been
    /// seen, where a crossfade reads as a flicker rather than a transition.
    @Published private(set) var animatesTranscriptTransition = false

    /// Guards against a second fetch while one is in flight, which `isLoadingTranscript`
    /// can't do while it starts out true
    private var isFetchingTranscript = false

    /// How long the transcript has to keep the placeholder up before its arrival is
    /// worth animating
    private static let transitionThreshold: Duration = .milliseconds(200)

    let episode: BaseEpisode?

    /// Assigned by the hosting controller, which owns playback
    var onPlay: () -> Void = {}

    /// Assigned by the hosting controller, which owns navigation. Absent where there are no
    /// episode details to open, such as an uploaded file or the player.
    var onEpisodeTapped: (() -> Void)?

    private let bookmarkManager: BookmarkManager

    init(bookmark: Bookmark,
         passage: String?,
         episode: BaseEpisode?,
         podcastTitle: String?,
         transcriptSnippet: BookmarkTranscriptSnippet? = nil,
         bookmarkManager: BookmarkManager = PlaybackManager.shared.bookmarkManager) {
        self.bookmark = bookmark
        self.passage = passage
        self.episode = episode
        self.podcastTitle = podcastTitle
        self.transcriptSnippet = transcriptSnippet
        self.bookmarkManager = bookmarkManager
        self.isLoadingTranscript = transcriptSnippet == nil && passage?.isEmpty == false && episode != nil
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

    /// Fetches the episode transcript and locates the passage in it
    func loadTranscript() async {
        guard transcriptSnippet == nil, !isFetchingTranscript,
              passage?.isEmpty == false, let episode else { return }

        let startedLoading = ContinuousClock.now

        isFetchingTranscript = true
        isLoadingTranscript = true

        let snippet = await bookmarkManager.capturedSnippet(for: bookmark, episode: episode)

        animatesTranscriptTransition = startedLoading.duration(to: .now) > Self.transitionThreshold
        transcriptSnippet = snippet

        isFetchingTranscript = false
        isLoadingTranscript = false
    }

    func refresh() {
        guard let bookmark = bookmarkManager.bookmark(for: bookmark.uuid) else { return }

        self.bookmark = bookmark
        self.passage = bookmark.passage
        relocatePassage()
    }

    /// Points the already-loaded transcript at the passage as it stands after an edit
    private func relocatePassage() {
        guard let transcript = transcriptSnippet?.transcript else { return }

        // The transcript is already up, so it's replaced in place rather than fading in
        // over the placeholder
        animatesTranscriptTransition = false

        transcriptSnippet = passage.flatMap { passage in
            BookmarkTranscriptSnippetExtractor.passageRange(for: passage, at: bookmark.passageLocation, in: transcript.attributedText)
                .map { BookmarkTranscriptSnippet(transcript: transcript, range: $0) }
        }
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
