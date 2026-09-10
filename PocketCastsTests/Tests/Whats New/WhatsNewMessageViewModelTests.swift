import PocketCastsServer
import XCTest

@testable import podcasts

final class WhatsNewMessageViewModelTests: XCTestCase {
    func testTitleComesFromTheContent() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        { "title": "Read along while you listen", "pages": [{ "blocks": [{ "type": "paragraph", "content": "…" }] }] }
        """))

        XCTAssertEqual(viewModel.title, "Read along while you listen")
    }

    /// Not every message titles its content, and the feed row's title is what the reader tapped.
    func testTitleFallsBackToTheSummary() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        { "pages": [{ "blocks": [{ "type": "paragraph", "content": "…" }] }] }
        """))

        XCTAssertEqual(viewModel.title, "Introducing episode transcripts")
    }

    func testPagesKeepTheirPublishedOrder() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        {
          "pages": [
            { "blocks": [{ "type": "heading", "level": 2, "text": "First" }] },
            { "blocks": [{ "type": "heading", "level": 2, "text": "Second" }] }
          ]
        }
        """))

        XCTAssertEqual(viewModel.pages.map(\.id), [0, 1])
        XCTAssertEqual(viewModel.pages.compactMap { $0.blocks.first?.headingText }, ["First", "Second"])
    }

    /// An action the allowlist won't open would draw a button that does nothing, so it never
    /// reaches the screen.
    func testActionsPointingSomewhereUnsupportedAreDropped() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        {
          "pages": [
            {
              "blocks": [
                { "type": "paragraph", "content": "…" },
                { "type": "action", "label": "Rate us", "url": "itms-apps://apps.apple.com/app/id414834813" },
                { "type": "action", "label": "Try transcripts", "url": "pocketcasts://podcasts" }
              ]
            }
          ]
        }
        """))

        XCTAssertEqual(viewModel.pages.first?.actions.map(\.label), ["Try transcripts"])
    }

    /// The buttons are pinned to the bottom of the page, so they're kept apart from the blocks that
    /// scroll rather than drawn where the catalog happened to put them.
    func testActionsAreKeptOutOfTheBlocksThatScroll() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        {
          "pages": [
            {
              "blocks": [
                { "type": "action", "label": "Try transcripts", "url": "pocketcasts://podcasts" },
                { "type": "paragraph", "content": "…" },
                { "type": "action", "label": "Read more", "url": "https://blog.pocketcasts.com" }
              ]
            }
          ]
        }
        """))

        let page = try XCTUnwrap(viewModel.pages.first)
        XCTAssertEqual(page.blocks.count, 1)
        XCTAssertEqual(page.actions.map(\.label), ["Try transcripts", "Read more"])
    }

    /// The poll's questions scroll with the rest of the page; only the button that sends them is
    /// pinned, so the block stays where it was published.
    func testAPollIsBothDrawnInPlaceAndPickedOutForItsButton() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        {
          "pages": [
            {
              "blocks": [
                { "type": "paragraph", "content": "…" },
                {
                  "type": "poll",
                  "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
                  "question": "What next?",
                  "options": [{ "id": "01K2Y2VJSSTJ66NPVQPM5YWFD1", "label": "Up Next controls" }]
                }
              ]
            }
          ]
        }
        """))

        let page = try XCTUnwrap(viewModel.pages.first)
        XCTAssertEqual(page.blocks.count, 2)
        XCTAssertEqual(page.poll?.pollId, "01K2Y2S65F22TQZQJVNAEXQKHT")
    }

    /// One button sends a page's answers, so it can only ask one poll's worth of questions.
    func testASecondPollOnAPageIsDropped() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        {
          "pages": [
            {
              "blocks": [
                {
                  "type": "poll",
                  "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
                  "question": "What next?",
                  "options": [{ "id": "01K2Y2VJSSTJ66NPVQPM5YWFD1", "label": "Up Next controls" }]
                },
                {
                  "type": "poll",
                  "pollId": "01K2Y3A7MC0R6VDBQF1WZS8HEJ",
                  "question": "And then?",
                  "options": [{ "id": "01K2Y3BJ6ZR8YH2QW4KFT7NAD5", "label": "Podcast discovery" }]
                }
              ]
            }
          ]
        }
        """))

        let page = try XCTUnwrap(viewModel.pages.first)
        XCTAssertEqual(page.blocks.count, 1)
        XCTAssertEqual(page.poll?.pollId, "01K2Y2S65F22TQZQJVNAEXQKHT")
    }

    /// Dropping the only block on a page would leave an empty one to swipe through.
    func testAPageLeftWithNothingToShowIsDropped() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(content: """
        {
          "pages": [
            { "blocks": [{ "type": "paragraph", "content": "…" }] },
            { "blocks": [{ "type": "action", "label": "Rate us", "url": "itms-apps://apps.apple.com/app/id414834813" }] }
          ]
        }
        """))

        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertEqual(viewModel.pages.map(\.id), [0])
    }

    // MARK: - Helpers

    /// A message whose summary is fixed and whose content is whatever the test is about.
    private func message(content: String) throws -> WhatsNewMessage {
        let json = """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
              "type": "new_feature",
              "publishedAt": "2026-08-17T08:00:00Z",
              "targeting": { "audiences": [] },
              "summary": { "title": "Introducing episode transcripts" },
              "content": \(content)
            }
          ]
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let catalog = try decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8))
        return try XCTUnwrap(catalog.messages.first)
    }
}

private extension WhatsNewBlock {
    var headingText: String? {
        guard case .heading(let heading) = self else { return nil }
        return heading.text
    }
}
