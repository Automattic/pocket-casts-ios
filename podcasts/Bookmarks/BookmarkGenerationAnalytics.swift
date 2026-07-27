import Foundation
import PocketCastsDataModel

/// The analytics for generating a bookmark's title and passage.
///
/// Kept in one place because two paths run the same pipeline — the edit sheet and the
/// background enrichment for bookmarks that never open it — and the events are only
/// comparable if both report them identically.
///
/// Nothing here sends transcript text, passage text, or titles: only their size.
enum BookmarkGenerationAnalytics {

    // MARK: - Passage

    static func passageCaptured(_ capture: BookmarkPassageCapture,
                                bookmark: Bookmark,
                                trigger: BookmarkEnrichmentTrigger,
                                source: BookmarkAnalyticsSource,
                                duration: TimeInterval) {
        track(.bookmarkPassageCaptured, bookmark: bookmark, source: source, properties: [
            "trigger": trigger,
            "duration_ms": milliseconds(duration),
            "word_count": wordCount(of: capture.snippet.text),
            "is_generated_transcript": capture.isGeneratedTranscript
        ])
    }

    static func passageCaptureFailed(_ reason: BookmarkPassageFailureReason,
                                     bookmark: Bookmark,
                                     trigger: BookmarkEnrichmentTrigger,
                                     source: BookmarkAnalyticsSource,
                                     duration: TimeInterval) {
        track(.bookmarkPassageCaptureFailed, bookmark: bookmark, source: source, properties: [
            "reason": reason,
            "trigger": trigger,
            "duration_ms": milliseconds(duration)
        ])
    }

    // MARK: - Title

    static func titleGenerated(_ attempt: BookmarkTitleAttempt,
                               bookmark: Bookmark,
                               trigger: BookmarkEnrichmentTrigger,
                               source: BookmarkAnalyticsSource) {
        track(.bookmarkTitleGenerated, bookmark: bookmark, source: source, properties: [
            "generator": attempt.generation.generator,
            "did_fall_back_to_server": attempt.generation.didFallBackToServer,
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
            "did_fall_back_to_server": error.didFallBackToServer,
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
