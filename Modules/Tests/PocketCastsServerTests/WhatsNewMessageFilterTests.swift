import Foundation
@testable import PocketCastsServer
import PocketCastsUtils
import XCTest

final class WhatsNewMessageFilterTests: XCTestCase {
    private let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"), includesPolls: true)
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
            let filter = WhatsNewMessageFilter(audience: audience, appVersion: Version("8.10"), includesPolls: true)
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
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: nil, includesPolls: true)
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

    // MARK: - Polls

    func testAResearchMessageIsHiddenWhenPollsAreNotIncluded() throws {
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"), includesPolls: false)

        XCTAssertFalse(filter.includes(try researchMessage(), at: now))
        XCTAssertTrue(filter.includes(try message(), at: now), "Only research messages depend on polls")
    }

    func testAResearchMessageIsShownWhenPollsAreIncluded() throws {
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"), includesPolls: true)

        XCTAssertTrue(filter.includes(try researchMessage(), at: now))
    }

    // MARK: - Install date

    /// Announcements and polls from before the install were news to whoever had the app back then.
    func testAnnouncementsAndPollsPublishedBeforeTheInstallAreHidden() throws {
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"), includesPolls: true, installDate: now)

        XCTAssertFalse(filter.includes(try message(type: "announcement"), at: now))
        XCTAssertFalse(filter.includes(try researchMessage(), at: now))
    }

    func testNewFeaturesTipsAndKnownIssuesPublishedBeforeTheInstallAreShown() throws {
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"), includesPolls: true, installDate: now)

        for type in ["new_feature", "tip", "known_issue"] {
            XCTAssertTrue(filter.includes(try message(type: type), at: now), "A \(type) is as useful to a new user as to anyone")
        }
    }

    func testAnnouncementsAndPollsPublishedAfterTheInstallAreShown() throws {
        let filter = WhatsNewMessageFilter(audience: .plus, appVersion: Version("8.10"), includesPolls: true, installDate: now.addingTimeInterval(-2.days))

        XCTAssertTrue(filter.includes(try message(type: "announcement"), at: now))
        XCTAssertTrue(filter.includes(try researchMessage(), at: now))
    }

    /// An install updated from an earlier version has no install date, and its user was there for
    /// everything the feed has.
    func testAnnouncementsAreShownWhenTheInstallDateIsUnknown() throws {
        XCTAssertTrue(filter.includes(try message(type: "announcement"), at: now))
    }

    // MARK: - Helpers

    private func researchMessage() throws -> WhatsNewMessage {
        let json = """
        {
          "id": "550e8400-e29b-41d4-a716-446655440003",
          "type": "research",
          "publishedAt": "\(iso8601(from: now.addingTimeInterval(-1.day)))",
          "targeting": {},
          "title": "Help shape the player",
          "poll": {
            "pollId": "550e8400-e29b-41d4-a716-446655440101",
            "pollKey": "player_improvements_2026",
            "question": "What should we improve next?",
            "options": [
              { "id": "550e8400-e29b-41d4-a716-446655440201", "pollOptionKey": "up_next_controls", "label": "Up Next controls" },
              { "id": "550e8400-e29b-41d4-a716-446655440202", "pollOptionKey": "podcast_discovery", "label": "Podcast discovery" }
            ]
          }
        }
        """
        return try WhatsNewCatalog.decoder.decode(WhatsNewMessage.self, from: Data(json.utf8))
    }

    private func message(type: String = "tip",
                         targeting: String = "{}",
                         publishedAt: Date? = nil,
                         expiresAt: Date? = nil) throws -> WhatsNewMessage {
        let expires = expiresAt.map { #", "expiresAt": "\#(iso8601(from: $0))""# } ?? ""
        let json = """
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "\(type)",
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
