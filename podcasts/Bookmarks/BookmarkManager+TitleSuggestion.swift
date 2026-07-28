import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension BookmarkManager {

    static var isTitleSuggestionEnabled: Bool {
        FeatureFlag.smartBookmarks.enabled
    }

    /// The transcript passage surrounding the bookmark, which the title is generated from.
    ///
    /// Returns nil when suggestions are disabled or the episode has no usable transcript.
    func transcriptSnippet(for bookmark: Bookmark, episode: BaseEpisode) async -> BookmarkTranscriptSnippet? {
        guard Self.isTitleSuggestionEnabled else {
            return nil
        }

        // Let the on-device model load while the transcript is fetched.
        prewarmTitleGeneration()

        return await BookmarkTranscriptSnippetExtractor().snippet(forTime: bookmark.time, episode: episode)
    }

    func capturedSnippet(for bookmark: Bookmark, episode: BaseEpisode) async -> BookmarkTranscriptSnippet? {
        guard Self.isTitleSuggestionEnabled, let passage = bookmark.passage, !passage.isEmpty else {
            return nil
        }

        return await BookmarkTranscriptSnippetExtractor().snippet(forPassage: passage, at: bookmark.passageLocation, episode: episode)
    }

    /// Returns nil when generation fails.
    func suggestTitle(from snippet: String, for bookmark: Bookmark, episode: BaseEpisode) async -> String? {
        let podcastTitle = bookmark.podcastUuid.flatMap { DataManager.sharedManager.findPodcast(uuid: $0)?.title }
        do {
            return try await generateTitle(transcriptSnippet: snippet, podcastTitle: podcastTitle, episodeTitle: episode.title)
        } catch {
            FileLog.shared.addMessage("[Bookmarks] Title suggestion failed: \(error)")
            return nil
        }
    }
}
