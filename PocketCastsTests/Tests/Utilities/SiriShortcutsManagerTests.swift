import Intents
import XCTest
@testable import podcasts

final class SiriShortcutsManagerTests: XCTestCase {
    func testDefaultSuggestionsIncludesLegacySleepTimerShortcut() {
        let suggestions = SiriShortcutsManager.shared.defaultSuggestions()

        XCTAssertTrue(suggestions.contains { $0.intent is SJSleepTimerIntent })
    }
}
