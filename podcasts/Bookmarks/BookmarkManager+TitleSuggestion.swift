import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension BookmarkManager {

    static var isTitleSuggestionEnabled: Bool {
        FeatureFlag.smartBookmarks.enabled
    }

    /// Returns nil when suggestions are disabled, the episode has no usable
    /// transcript, or generation fails.
    func suggestTitle(for bookmark: Bookmark) async -> String? {
        guard Self.isTitleSuggestionEnabled, let episode = episode(for: bookmark) else {
            return nil
        }

        // Let the on-device model load while the transcript is fetched.
        prewarmTitleGeneration()

        guard let snippet = await BookmarkTranscriptSnippetExtractor().snippet(forTime: bookmark.time, episode: episode) else {
            return nil
        }

        let podcastTitle = bookmark.podcastUuid.flatMap { DataManager.sharedManager.findPodcast(uuid: $0)?.title }
        do {
            return try await generateTitle(transcriptSnippet: snippet, podcastTitle: podcastTitle, episodeTitle: episode.title)
        } catch {
            FileLog.shared.addMessage("[Bookmarks] Title suggestion failed: \(error)")
            return nil
        }
    }
}
