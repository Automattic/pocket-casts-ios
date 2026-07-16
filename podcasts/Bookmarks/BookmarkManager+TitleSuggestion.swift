import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension BookmarkManager {

    /// Whether bookmark title suggestions can be generated at all.
    static var isTitleSuggestionEnabled: Bool {
        FeatureFlag.smartBookmarks.enabled
    }

    /// Generates a suggested title for the bookmark from the transcript text
    /// surrounding its position. Returns nil when suggestions are disabled, the
    /// episode has no usable transcript, or generation fails — the bookmark
    /// keeps its original title in every failure case.
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
