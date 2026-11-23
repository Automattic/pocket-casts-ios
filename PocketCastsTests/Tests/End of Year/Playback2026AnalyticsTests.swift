import Testing
import PlaybackKit
@testable import podcasts

struct Playback2026AnalyticsTests {
    static let events: [PlaybackAnalyticsEvent] = [
        .archetypeAssigned(archetype: .flaneur),
        .storyShown(story: .cover, index: 0, count: 12, revisit: false),
        .quizRevealed(story: .top1Show, correct: .noGuess, reason: .timeout),
        .storyShare(story: .summary, variant: .bubbles),
        .storyShared(story: .top5Shows, from: .screenshot, activity: nil, variant: nil),
        .replayButtonTapped,
        .storiesDismissed(source: .closeButton, story: .ending, finished: true),
        .storiesFailedToLoad,
    ]

    @Test(arguments: events)
    func sendsTheEventWithTheSchemaNameAndCurrentYear(_ event: PlaybackAnalyticsEvent) {
        let sent = Playback2026Analytics.analytics(for: event)

        #expect(sent.count == 1)
        #expect(sent.first?.event.eventName == event.name)
        #expect(sent.first?.properties == event.properties.merging(["current_year": "2026"]) { $1 })
    }

    @Test func storyShownCarriesTheStoryAndPosition() {
        let sent = Playback2026Analytics.analytics(for: .storyShown(story: .yearVsYear, index: 6, count: 12, revisit: true))

        // The schema's value, as Android sent it in 2025; iOS 2025 sent `year_over_year`.
        #expect(sent.first?.event == .endOfYearStoryShown)
        #expect(sent.first?.properties == ["story": "year_vs_year", "index": "6", "count": "12", "revisit": "true", "current_year": "2026"])
    }

    @Test func shareSheetShareAlsoSendsPlaybackShared() {
        let sent = Playback2026Analytics.analytics(for: .storyShared(story: .summary, from: .button, activity: "com.apple.UIKit.activity.CopyToPasteboard", variant: .grid))

        let shared = ["story": "summary", "from": "button", "activity": "com.apple.UIKit.activity.CopyToPasteboard", "variant": "a", "current_year": "2026"]
        #expect(sent.map(\.event) == [.endOfYearStoryShared, .playbackShared])
        #expect(sent.first?.properties == shared)
        #expect(sent.last?.properties == shared.merging(["source": "end_of_year"]) { $1 })
    }
}
