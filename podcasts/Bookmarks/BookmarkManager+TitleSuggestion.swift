import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/// A finished title generation, held onto so the caller can report it once it knows whether
/// the title was applied outright or only offered as a suggestion.
struct BookmarkTitleAttempt {
    let generation: BookmarkManager.TitleGeneration
    let duration: TimeInterval

    var title: String { generation.title }
}

extension BookmarkManager {

    static var isTitleSuggestionEnabled: Bool {
        FeatureFlag.smartBookmarks.enabled
    }

    /// The transcript passage surrounding the bookmark, which the title is generated from.
    ///
    /// Returns nil when suggestions are disabled or the episode has no usable transcript.
    func transcriptSnippet(for bookmark: Bookmark, episode: BaseEpisode,
                           trigger: BookmarkEnrichmentTrigger,
                           source: BookmarkAnalyticsSource) async -> BookmarkTranscriptSnippet? {
        guard Self.isTitleSuggestionEnabled else {
            return nil
        }

        // Let the on-device model load while the transcript is fetched.
        prewarmTitleGeneration()

        let started = Date()
        let result = await BookmarkTranscriptSnippetExtractor().capture(forTime: bookmark.time, referenceTime: bookmark.referenceTime, episode: episode)
        let duration = Date().timeIntervalSince(started)

        // The sheet can be dismissed, or saved, while the transcript is still loading
        guard !Task.isCancelled else {
            BookmarkGenerationAnalytics.passageCaptureFailed(.cancelled, bookmark: bookmark, trigger: trigger, source: source, duration: duration)
            return nil
        }

        switch result {
        case .success(let capture):
            BookmarkGenerationAnalytics.passageCaptured(capture, bookmark: bookmark, trigger: trigger, source: source, duration: duration)
            return capture.snippet
        case .failure(let reason):
            BookmarkGenerationAnalytics.passageCaptureFailed(reason, bookmark: bookmark, trigger: trigger, source: source, duration: duration)
            return nil
        }
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
    func enrich(_ bookmark: Bookmark, source: BookmarkAnalyticsSource = .unknown) async {
        guard Self.isTitleSuggestionEnabled, let episode = episode(for: bookmark),
              let snippet = await transcriptSnippet(for: bookmark, episode: episode, trigger: .background, source: source) else { return }

        let attempt = await suggestTitle(from: snippet.text, for: bookmark, episode: episode, trigger: .background, source: source)
        let title = attempt.map { String($0.title.trim().prefix(Constants.Values.bookmarkMaxTitleLength)) }

        guard let attempt, let title, !title.isEmpty else {
            // Nothing to rename to, but the passage is still worth keeping for the edit sheet
            bookmark.passage = snippet.text
            bookmark.passageLocation = snippet.range.location
            bookmark.referenceTime = snippet.referenceTime
            return
        }

        FileLog.shared.addMessage("[Bookmarks] Generated a title for bookmark \(bookmark.uuid)")

        BookmarkGenerationAnalytics.titleGenerated(attempt, bookmark: bookmark, trigger: .background, source: source)

        let passage = BookmarkUpdateParameters.Passage(text: snippet.text, location: snippet.range.location)
        await update(.init(title: title, passage: passage, referenceTime: snippet.referenceTime), for: bookmark)
    }

    /// Returns nil when generation fails.
    ///
    /// Reports its own failures, but leaves reporting a success to the caller, which is the only
    /// one that knows whether the title ends up applied or merely offered.
    func suggestTitle(from snippet: String, for bookmark: Bookmark, episode: BaseEpisode,
                      trigger: BookmarkEnrichmentTrigger,
                      source: BookmarkAnalyticsSource) async -> BookmarkTitleAttempt? {
        let podcastTitle = bookmark.podcastUuid.flatMap { DataManager.sharedManager.findPodcast(uuid: $0)?.title }
        let started = Date()
        do {
            let generation = try await generateTitle(transcriptSnippet: snippet, podcastTitle: podcastTitle, episodeTitle: episode.title)
            let duration = Date().timeIntervalSince(started)

            guard !Task.isCancelled else {
                let cancelled = TitleGenerationError(reason: .cancelled, generator: generation.generator, didFallBackToServer: generation.didFallBackToServer)
                BookmarkGenerationAnalytics.titleGenerationFailed(cancelled, bookmark: bookmark, trigger: trigger, source: source, duration: duration)
                return nil
            }

            return BookmarkTitleAttempt(generation: generation, duration: duration)
        } catch {
            FileLog.shared.addMessage("[Bookmarks] Title suggestion failed: \(error)")

            let failure = error as? TitleGenerationError
                ?? TitleGenerationError(reason: .unknown, generator: .server, didFallBackToServer: false)
            BookmarkGenerationAnalytics.titleGenerationFailed(failure, bookmark: bookmark, trigger: trigger, source: source, duration: Date().timeIntervalSince(started))
            return nil
        }
    }
}
