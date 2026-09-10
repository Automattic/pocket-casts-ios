import PocketCastsServer
import XCTest

@testable import podcasts

@MainActor
final class WhatsNewFeedViewModelTests: XCTestCase {
    private let messages = WhatsNewCatalog.mock.messages

    func testItemsAreMostRecentlyPublishedFirst() {
        let viewModel = WhatsNewFeedViewModel(messages: messages.shuffled())

        XCTAssertEqual(viewModel.items.map(\.publishedAt), messages.map(\.publishedAt).sorted(by: >))
    }

    /// The detail screen needs the whole message, not just what the row happened to show.
    func testSelectingARowHandsOverItsMessage() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages)
        var selected: WhatsNewMessage?
        viewModel.onSelect = { selected = $0 }

        let item = try XCTUnwrap(viewModel.items.last)
        viewModel.select(item)

        XCTAssertEqual(selected?.id, item.id)
    }

    /// Opening the detail is what marks a message read.
    func testSelectingARowMarksItRead() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages)

        let item = try XCTUnwrap(viewModel.items.first)
        XCTAssertTrue(item.isUnread)

        viewModel.select(item)

        XCTAssertEqual(viewModel.items.first?.isUnread, false)
    }

    func testReadMessagesStartRead() {
        let viewModel = WhatsNewFeedViewModel(messages: messages, readMessageIDs: Set(messages.map(\.id)))

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// Everything on a message's only page can be dropped — an action the allowlist won't open is
    /// the app's own doing — which would leave a row that opens onto nothing.
    func testMessagesWithNothingToShowNeverReachTheFeed() throws {
        let messages = try decodedMessages(json: """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00Z",
              "targeting": { "audiences": [] },
              "summary": { "title": "Sort your Up Next" },
              "content": { "pages": [{ "blocks": [{ "type": "paragraph", "content": "…" }] }] }
            },
            {
              "id": "01K2Y3D5J1H7QZP0B6RXKA4N3T",
              "type": "tip",
              "publishedAt": "2026-08-18T08:00:00Z",
              "targeting": { "audiences": [] },
              "summary": { "title": "Rate us" },
              "content": {
                "pages": [
                  { "blocks": [{ "type": "action", "label": "Rate us", "url": "itms-apps://apps.apple.com/app/id414834813" }] }
                ]
              }
            }
          ]
        }
        """)

        let viewModel = WhatsNewFeedViewModel(messages: messages)

        XCTAssertEqual(viewModel.items.map(\.title), ["Sort your Up Next"])
    }

    func testReadingEverythingClearsEveryIndicator() {
        let viewModel = WhatsNewFeedViewModel(messages: messages)
        XCTAssertTrue(viewModel.hasUnreadItems)

        viewModel.markAllAsRead()

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    // MARK: - Helpers

    private func decodedMessages(json: String) throws -> [WhatsNewMessage] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8)).messages
    }
}
