import PocketCastsServer
import XCTest

@testable import podcasts

final class WhatsNewActionEventTests: XCTestCase {
    func testTheEventsThisBuildImplementsAreRecognised() throws {
        for event in [WhatsNewActionEvent.openPodcasts, .openDiscover, .openUpNext, .openPlaylists, .openProfile, .openSettings, .openUpsell] {
            XCTAssertEqual(WhatsNewActionEvent(action: try action(event: event.rawValue)), event)
        }
    }

    /// Events are free text agreed between the platforms, so the app is going to meet ones it has
    /// never heard of. That costs the page its button rather than the whole message.
    func testAnEventThisBuildDoesNotImplementIsNotRecognised() throws {
        let events = [
            "open_something_from_a_later_release",
            "OPEN_PODCASTS",
            "open podcasts",
            "https://blog.pocketcasts.com",
            "pocketcasts://podcasts"
        ]

        for event in events {
            XCTAssertNil(WhatsNewActionEvent(action: try action(event: event)), "\(event) should not resolve to a behaviour")
        }
    }

    // MARK: - Helpers

    private func action(event: String) throws -> WhatsNewAction {
        let json = """
        { "event": "\(event)", "label": "Try it" }
        """
        let decoder = JSONDecoder()

        return try decoder.decode(WhatsNewAction.self, from: Data(json.utf8))
    }
}
