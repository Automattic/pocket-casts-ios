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

        return await BookmarkTranscriptSnippetExtractor().snippet(forTime: bookmark.time, referenceTime: bookmark.referenceTime, episode: episode)
    }

    func capturedSnippet(for bookmark: Bookmark, episode: BaseEpisode) async -> BookmarkTranscriptSnippet? {
        guard Self.isTitleSuggestionEnabled, let passage = bookmark.passage, !passage.isEmpty else {
            return nil
        }

        return await BookmarkTranscriptSnippetExtractor().snippet(forPassage: passage, at: bookmark.passageLocation, episode: episode)
    }

    /// Generates a title and passage for a bookmark and saves them.
    ///
    /// Bookmarks made with a headphone button, in CarPlay, or while the app is in the background
    /// never open the edit sheet, so this is the only thing that titles them.
    func enrich(_ bookmark: Bookmark) async {
        guard Self.isTitleSuggestionEnabled, let episode = episode(for: bookmark),
              let snippet = await transcriptSnippet(for: bookmark, episode: episode) else { return }

        let suggestion = await suggestTitle(from: snippet.text, for: bookmark, episode: episode)
        let title = suggestion.map { String($0.trim().prefix(Constants.Values.bookmarkMaxTitleLength)) }

        guard let title, !title.isEmpty else {
            // Nothing to rename to, but the passage is still worth keeping for the edit sheet
            let now = Date()
            await dataManager.update(bookmark: bookmark,
                                     passage: snippet.text,
                                     passageLocation: snippet.range.location,
                                     passageModified: now,
                                     referenceTime: snippet.referenceTime,
                                     referenceTimeModified: snippet.referenceTime != nil ? now : nil)
            return
        }

        FileLog.shared.addMessage("[Bookmarks] Generated a title for bookmark \(bookmark.uuid)")

        let passage = BookmarkUpdateParameters.Passage(text: snippet.text, location: snippet.range.location)
        await update(.init(title: title, passage: passage, referenceTime: snippet.referenceTime), for: bookmark)
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
