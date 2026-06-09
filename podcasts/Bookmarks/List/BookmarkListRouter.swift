import PocketCastsDataModel
import UIKit

protocol BookmarkListRouter: AnyObject {
    func bookmarkPlay(_ bookmark: Bookmark)
    func bookmarkEdit(_ bookmark: Bookmark)
    func bookmarkShare(_ bookmark: Bookmark)
    func bookmarkDetail(_ bookmark: Bookmark)

    /// Optional: Dismisses the presented bookmark list, if applicable.
    func dismissBookmarksList()

    /// Called when a view model needs to present a view controller, such as an alert.
    func presentBookmarkController(_ controller: UIViewController)
}

extension BookmarkListRouter {
    func dismissBookmarksList() { /* NOOP */ }
    func bookmarkDetail(_ bookmark: Bookmark) { /* NOOP */ }
}

// MARK: - UIViewController subclass default implementation

extension BookmarkListRouter where Self: UIViewController {
    func presentBookmarkController(_ controller: UIViewController) {
        present(controller, animated: true)
    }

    func presentBookmarkEditor(bookmark: Bookmark, bookmarkManager: BookmarkManager, analyticsSource: BookmarkAnalyticsSource, useAppTheme: Bool = true, onSaved: @escaping () -> Void) {
        guard let episode = bookmark.episode as? Episode ?? DataManager.sharedManager.findBaseEpisode(uuid: bookmark.episodeUuid) as? Episode else {
            bookmarkEdit(bookmark)
            return
        }

        let transcriptManager = TranscriptManager(episodeUUID: episode.uuid, podcastUUID: episode.podcastUuid)
        Task {
            do {
                let transcript = try await transcriptManager.loadTranscript()
                let cues = transcript.cues
                let fullText = transcript.attributedText.string
                guard !cues.isEmpty else {
                    await MainActor.run { self.bookmarkEdit(bookmark) }
                    return
                }

                let vm = TranscriptSelectionViewModel(
                    bookmark: bookmark,
                    cues: cues,
                    fullText: fullText,
                    bookmarkManager: bookmarkManager,
                    existingTitle: bookmark.title
                )
                await MainActor.run {
                    let controller = TranscriptSelectionViewController(viewModel: vm, episode: episode, useAppTheme: useAppTheme) { _, _ in
                        onSaved()
                    }
                    controller.source = analyticsSource
                    let presenter = self.presentedViewController ?? self
                    presenter.present(controller, animated: true)
                }
            } catch {
                await MainActor.run { self.bookmarkEdit(bookmark) }
            }
        }
    }
}
