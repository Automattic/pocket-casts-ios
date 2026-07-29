import Foundation
import PocketCastsDataModel

/// The analytics for a bookmark's generated title, and for editing the passage it's written from.
///
/// Kept in one place because two paths run the same pipeline — the edit sheet and the
/// background enrichment for bookmarks that never open it — and the events are only
/// comparable if both report them identically.
///
/// Nothing here sends transcript text, passage text, or titles: only their size.
enum BookmarkGenerationAnalytics {

    // MARK: - Title

    static func titleGenerated(_ attempt: BookmarkTitleAttempt,
                               bookmark: Bookmark,
                               trigger: BookmarkEnrichmentTrigger,
                               source: BookmarkAnalyticsSource) {
        track(.bookmarkTitleGenerated, bookmark: bookmark, source: source, properties: [
            "generator": attempt.generation.generator,
            "duration_ms": milliseconds(attempt.duration),
            "word_count": wordCount(of: attempt.title),
            "trigger": trigger
        ])
    }

    static func titleGenerationFailed(_ error: BookmarkManager.TitleGenerationError,
                                      bookmark: Bookmark,
                                      trigger: BookmarkEnrichmentTrigger,
                                      source: BookmarkAnalyticsSource,
                                      duration: TimeInterval) {
        track(.bookmarkTitleGenerationFailed, bookmark: bookmark, source: source, properties: [
            "reason": error.reason,
            "generator": error.generator,
            "duration_ms": milliseconds(duration),
            "trigger": trigger
        ])
    }

    // MARK: - Editing

    static func suggestionTapped(bookmark: Bookmark, source: BookmarkAnalyticsSource) {
        track(.bookmarkTitleSuggestionTapped, bookmark: bookmark, source: source)
    }

    static func passageEditorShown(bookmark: Bookmark, source: BookmarkAnalyticsSource) {
        track(.bookmarkPassageEditorShown, bookmark: bookmark, source: source)
    }

    static func passageEditorDismissed(bookmark: Bookmark,
                                       source: BookmarkAnalyticsSource,
                                       passage: String,
                                       didChange: Bool) {
        track(.bookmarkPassageEditorDismissed, bookmark: bookmark, source: source, properties: [
            "passage_changed": didChange,
            "word_count": wordCount(of: passage)
        ])
    }

    // MARK: - Helpers

    /// Adds the episode and podcast every bookmark event carries. `podcast_uuid` is left off
    /// rather than faked for bookmarks on uploaded files, which have no podcast.
    private static func track(_ event: AnalyticsEvent,
                              bookmark: Bookmark,
                              source: BookmarkAnalyticsSource,
                              properties: [String: Sendable] = [:]) {
        var properties = properties
        properties["episode_uuid"] = bookmark.episodeUuid
        if let podcastUuid = bookmark.podcastUuid {
            properties["podcast_uuid"] = podcastUuid
        }

        Analytics.track(event, source: source, properties: properties)
    }

    private static func milliseconds(_ duration: TimeInterval) -> Int {
        Int((duration * 1000).rounded())
    }

    private static func wordCount(of text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }
}
