import Foundation
@testable import PocketCastsServer
import PocketCastsUtils
import XCTest

final class WhatsNewMessageFilterTests: XCTestCase {
    private let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"))
    private let now = Date(timeIntervalSince1970: 1_787_000_000)

    // MARK: - Audience

    func testAMessageAimedAtTheUsersTierIsShown() throws {
        let message = try message(targeting: #"{ "audiences": ["plus", "patron"] }"#)

        XCTAssertTrue(filter.includes(message, at: now))
    }

    func testAMessageAimedAtAnotherTierIsHidden() throws {
        let message = try message(targeting: #"{ "audiences": ["free"] }"#)

        XCTAssertFalse(filter.includes(message, at: now))
    }

    func testAMessageWithNoAudiencesIsShownToEveryone() throws {
        let message = try message(targeting: "{}")

        for audience in [WhatsNewAudience.free, .plus, .patron] {
            let filter = WhatsNewMessageFilter(audience: audience, appVersion: Version("8.10"))
            XCTAssertTrue(filter.includes(message, at: now), "\(audience) should see a message aimed at nobody in particular")
        }
    }

    /// A tier published after this build shipped can't be evaluated, so the message stays hidden
    /// rather than reaching everyone.
    func testAMessageAimedOnlyAtAnUnknownTierIsHidden() throws {
        let message = try message(targeting: #"{ "audiences": ["future_tier"] }"#)

        XCTAssertFalse(filter.includes(message, at: now))
    }

    // MARK: - Minimum app version

    func testABuildNewerThanTheMinimumIsShownTheMessage() throws {
        let message = try message(targeting: #"{ "minimumAppVersion": "8.9" }"#)

        XCTAssertTrue(filter.includes(message, at: now))
    }

    func testTheBuildTheMinimumAsksForIsShownTheMessage() throws {
        let message = try message(targeting: #"{ "minimumAppVersion": "8.10" }"#)

        XCTAssertTrue(filter.includes(message, at: now))
    }

    func testAnOlderBuildIsNotShownTheMessage() throws {
        let message = try message(targeting: #"{ "minimumAppVersion": "8.11" }"#)

        XCTAssertFalse(filter.includes(message, at: now))
    }

    /// Comparing the versions as text would put 8.10 before 8.9.
    func testVersionComponentsAreComparedAsNumbers() throws {
        let message = try message(targeting: #"{ "minimumAppVersion": "8.9.1" }"#)

        XCTAssertTrue(filter.includes(message, at: now))
    }

    /// The build ships as 8.10, so a minimum written out as 8.10.0 asks for the same version.
    func testATrailingZeroDoesNotMakeTheMinimumNewer() throws {
        let message = try message(targeting: #"{ "minimumAppVersion": "8.10.0" }"#)

        XCTAssertTrue(filter.includes(message, at: now))
    }

    func testAMessageGatedOnAVersionIsHiddenWhenTheAppVersionIsUnknown() throws {
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: nil)
        let gated = try message(targeting: #"{ "minimumAppVersion": "8.9" }"#)
        let ungated = try message(targeting: "{}")

        XCTAssertFalse(filter.includes(gated, at: now))
        XCTAssertTrue(filter.includes(ungated, at: now), "A message with no minimum is still for every build")
    }

    func testAMessageGatedOnSomethingThatIsNotAVersionIsHidden() throws {
        let message = try message(targeting: #"{ "minimumAppVersion": "8.10-beta" }"#)

        XCTAssertFalse(filter.includes(message, at: now))
    }

    // MARK: - Publication and expiry

    func testAMessageThatIsNotPublishedYetIsHidden() throws {
        let message = try message(publishedAt: now.addingTimeInterval(1.hour))

        XCTAssertFalse(filter.includes(message, at: now))
    }

    /// The server leaves expired messages out of the catalog, but a cached one can outlive them.
    func testAnExpiredMessageIsHidden() throws {
        let message = try message(expiresAt: now.addingTimeInterval(-1.hour))

        XCTAssertFalse(filter.includes(message, at: now))
    }

    func testAMessageThatHasNotExpiredYetIsShown() throws {
        let message = try message(expiresAt: now.addingTimeInterval(1.hour))

        XCTAssertTrue(filter.includes(message, at: now))
    }

    func testAMessageWithNoExpiryNeverExpires() throws {
        let message = try message()

        XCTAssertTrue(filter.includes(message, at: now.addingTimeInterval(365.days)))
    }

    // MARK: - Helpers

    private func message(targeting: String = "{}",
                         publishedAt: Date? = nil,
                         expiresAt: Date? = nil) throws -> WhatsNewMessage {
        let expires = expiresAt.map { #", "expiresAt": "\#(iso8601(from: $0))""# } ?? ""
        let json = """
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "tip",
          "publishedAt": "\(iso8601(from: publishedAt ?? now.addingTimeInterval(-1.day)))"\(expires),
          "targeting": \(targeting),
          "title": "Sort your Up Next",
          "pages": [
            {
              "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
              "heading": "Put the queue in the order you want",
              "description": "…"
            }
          ]
        }
        """
        return try WhatsNewCatalog.decoder.decode(WhatsNewMessage.self, from: Data(json.utf8))
    }

    private func iso8601(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
