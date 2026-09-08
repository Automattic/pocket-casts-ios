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

    func testReadingEverythingClearsEveryIndicator() {
        let viewModel = WhatsNewFeedViewModel(messages: messages)
        XCTAssertTrue(viewModel.hasUnreadItems)

        viewModel.markAllAsRead()

        XCTAssertFalse(viewModel.hasUnreadItems)
    }
}
