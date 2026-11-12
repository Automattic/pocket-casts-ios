import PlaybackKit
import PocketCastsUtils

/// Sends Playback 2026's analytics: the `end_of_year_*` events Playback 2025 sent, with the same
/// names and story values so 2026 compares with 2025, and `current_year` on every one (PCIOS-1262).
///
/// PlaybackKit derives the events inside the stories from the page (``PlaybackAnalyticsEvent``).
/// The app sends the ones around them: the Podcasts sheet, the Profile banner and the stories
/// opening.
enum Playback2026Analytics {
    /// `end_of_year_stories_shown`'s `source`.
    enum Source: String {
        case modal
        case profile
        case userLogin = "user_login"
    }

    static func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        Analytics.track(event, properties: withYear(properties))
    }

    /// An event from inside the stories.
    static func track(_ event: PlaybackAnalyticsEvent) {
        let events = analytics(for: event)
        if events.isEmpty {
            FileLog.shared.addMessage("Playback 2026: no analytics event for \(event.name)")
        }
        for (event, properties) in events {
            Analytics.track(event, properties: properties)
        }
    }

    /// What `track(_:)` sends for an event from inside the stories, in order,
    /// `current_year` included. A share through the share sheet also sends `playback_shared`, as
    /// 2025 did.
    static func analytics(for event: PlaybackAnalyticsEvent) -> [(event: AnalyticsEvent, properties: [String: String])] {
        guard let analyticsEvent = analyticsEvent(for: event) else { return [] }
        let properties = withYear(event.properties)
        var events = [(event: analyticsEvent, properties: properties)]
        if case .storyShared(_, .button, _, _) = event {
            events.append((.playbackShared, properties.merging(["source": "end_of_year"]) { $1 }))
        }
        return events
    }

    private static func analyticsEvent(for event: PlaybackAnalyticsEvent) -> AnalyticsEvent? {
        switch event {
        case .archetypeAssigned: .endOfYearArchetypeAssigned
        case .storyShown: .endOfYearStoryShown
        case .quizRevealed: .endOfYearQuizRevealed
        case .storyShare: .endOfYearStoryShare
        case .storyShared: .endOfYearStoryShared
        case .replayButtonTapped: .endOfYearStoryReplayButtonTapped
        case .storiesDismissed: .endOfYearStoriesDismissed
        case .storiesFailedToLoad: .endOfYearStoriesFailedToLoad
        @unknown default: nil
        }
    }

    private static func withYear(_ properties: [String: String]) -> [String: String] {
        properties.merging(["current_year": String(Playback2026.year)]) { $1 }
    }
}
