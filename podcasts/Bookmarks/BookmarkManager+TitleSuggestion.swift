import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension BookmarkManager {

    static var isTitleSuggestionEnabled: Bool {
        FeatureFlag.smartBookmarks.enabled
    }

    /// The transcript text surrounding the bookmark, which the title is generated from.
    ///
    /// Returns nil when suggestions are disabled or the episode has no usable transcript.
    func transcriptSnippet(for bookmark: Bookmark) async -> String? {
        guard Self.isTitleSuggestionEnabled, let episode = episode(for: bookmark) else {
            return nil
        }

        // Let the on-device model load while the transcript is fetched.
        prewarmTitleGeneration()

        return await BookmarkTranscriptSnippetExtractor().snippet(forTime: bookmark.time, episode: episode)
    }

    /// Returns nil when generation fails.
    func suggestTitle(from snippet: String, for bookmark: Bookmark) async -> String? {
        let podcastTitle = bookmark.podcastUuid.flatMap { DataManager.sharedManager.findPodcast(uuid: $0)?.title }
        do {
            return try await generateTitle(transcriptSnippet: snippet, podcastTitle: podcastTitle, episodeTitle: episode(for: bookmark)?.title)
        } catch {
            FileLog.shared.addMessage("[Bookmarks] Title suggestion failed: \(error)")
            return nil
        }
    }
}
