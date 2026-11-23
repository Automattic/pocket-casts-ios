import Intents
import XCTest
@testable import podcasts

final class SiriShortcutsManagerTests: XCTestCase {
    func testDefaultSuggestionsIncludesLegacySleepTimerShortcut() {
        let suggestions = SiriShortcutsManager.shared.defaultSuggestions()

        XCTAssertTrue(suggestions.contains { $0.intent is SJSleepTimerIntent })
    }

    func testBurstOfPodcastChangesPublishesOnceAfterTheBurst() {
        let manager = PublishCountingSiriShortcutsManager()
        manager.setup()
        XCTAssertEqual(manager.publishCount, 1)

        for _ in 0..<50 {
            NotificationCenter.default.post(name: Constants.Notifications.podcastAdded, object: nil)
        }
        NotificationCenter.default.post(name: Constants.Notifications.podcastDeleted, object: nil)
        XCTAssertEqual(manager.publishCount, 1)

        let published = expectation(for: NSPredicate { _, _ in manager.publishCount == 2 }, evaluatedWith: nil)
        wait(for: [published], timeout: 5)

        let republished = expectation(for: NSPredicate { _, _ in manager.publishCount > 2 }, evaluatedWith: nil)
        republished.isInverted = true
        wait(for: [republished], timeout: 2)
    }
}

private final class PublishCountingSiriShortcutsManager: SiriShortcutsManager {
    private let lock = NSLock()
    private var count = 0

    var publishCount: Int {
        lock.withLock { count }
    }

    override func addDefaultSuggestions() {}

    override func publishSubscribedPodcasts() {
        lock.withLock { count += 1 }
    }
}
