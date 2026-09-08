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

        XCTAssertEqual(viewModel.pages.first?.blocks.count, 2)
        XCTAssertEqual(viewModel.pages.first?.blocks.compactMap { $0.actionLabel }, ["Try transcripts"])
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

    var actionLabel: String? {
        guard case .action(let action) = self else { return nil }
        return action.label
    }
}
