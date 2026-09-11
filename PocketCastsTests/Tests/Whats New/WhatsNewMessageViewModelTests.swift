import PocketCastsServer
import XCTest

@testable import podcasts

@MainActor
final class WhatsNewMessageViewModelTests: XCTestCase {
    /// The title is the message's own, the same one the feed row the reader tapped shows.
    func testTitleIsTheMessageTitle() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(pages: onePage))

        XCTAssertEqual(viewModel.title, "Introducing episode transcripts")
    }

    func testPagesKeepTheirPublishedOrder() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(pages: """
        [
          \(page(heading: "First")),
          \(page(heading: "Second"))
        ]
        """))

        XCTAssertEqual(viewModel.pages.map(\.id), [0, 1])
        XCTAssertEqual(viewModel.pages.map(\.heading), ["First", "Second"])
    }

    func testAPageCarriesTheImageAndTextItWasPublishedWith() throws {
        let page = try XCTUnwrap(WhatsNewMessageViewModel(message: try message(pages: onePage)).pages.first)

        XCTAssertEqual(page.image.url, URL(string: "https://static.pocketcasts.com/a.webp"))
        XCTAssertEqual(page.image.alt, "Episode transcript open beside the player")
        XCTAssertEqual(page.heading, "Read along while you listen")
        XCTAssertEqual(page.description, "Search a transcript and follow the conversation.")
    }

    func testAnActionIsResolvedToTheBehaviourItNames() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(pages: """
        [\(page(heading: "Try transcripts", action: #"{ "event": "open_podcasts", "label": "Try transcripts" }"#))]
        """))

        XCTAssertEqual(viewModel.pages.first?.action?.label, "Try transcripts")
        XCTAssertEqual(viewModel.pages.first?.action?.event, .openPodcasts)
    }

    /// A button for an event this build doesn't implement would go nowhere, so the page keeps its
    /// content and loses only the button.
    func testAnActionNamingAnEventThisBuildDoesNotImplementIsDropped() throws {
        let viewModel = WhatsNewMessageViewModel(message: try message(pages: """
        [\(page(heading: "Read along", action: #"{ "event": "open_something_from_a_later_release", "label": "Open it" }"#))]
        """))

        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertEqual(viewModel.pages.first?.heading, "Read along")
        XCTAssertNil(viewModel.pages.first?.action)
    }

    // MARK: - Research

    func testAResearchMessageIsAPollRatherThanPages() throws {
        let viewModel = WhatsNewMessageViewModel(message: try researchMessage())

        XCTAssertTrue(viewModel.pages.isEmpty)

        let research = try XCTUnwrap(viewModel.research)
        XCTAssertEqual(research.description, "Which improvement would make the biggest difference?")
        XCTAssertEqual(research.poll.question, "What should we improve next?")
        XCTAssertEqual(research.poll.options.map(\.label), ["Up Next controls", "Podcast discovery"])
    }

    /// Picking an option is the reader changing their mind until they continue, so nothing is
    /// reported and the poll stays open.
    func testPickingAnOptionDoesNotAnswerThePoll() throws {
        let viewModel = WhatsNewMessageViewModel(message: try researchMessage())
        let research = try XCTUnwrap(viewModel.research)
        var answered: [String] = []
        viewModel.onRespond = { _, option in answered.append(option.pollOptionKey) }

        viewModel.select(research.poll.options[0])
        viewModel.select(research.poll.options[1])

        XCTAssertEqual(viewModel.selectedOptionID, research.poll.options[1].id)
        XCTAssertFalse(viewModel.hasResponded)
        XCTAssertTrue(answered.isEmpty)
    }

    /// There's nothing to send until something is picked.
    func testThePollCannotBeAnsweredUntilAnOptionIsPicked() throws {
        let viewModel = WhatsNewMessageViewModel(message: try researchMessage())
        let research = try XCTUnwrap(viewModel.research)

        XCTAssertFalse(viewModel.canSubmitResponse)
        viewModel.submitResponse()
        XCTAssertFalse(viewModel.hasResponded)

        viewModel.select(research.poll.options[0])

        XCTAssertTrue(viewModel.canSubmitResponse)
    }

    func testContinuingAnswersThePollWithTheOptionThatWasPicked() throws {
        let viewModel = WhatsNewMessageViewModel(message: try researchMessage())
        let research = try XCTUnwrap(viewModel.research)
        var answered: [String] = []
        viewModel.onRespond = { _, option in answered.append(option.pollOptionKey) }

        viewModel.select(research.poll.options[1])
        viewModel.submitResponse()

        XCTAssertTrue(viewModel.hasResponded)
        XCTAssertFalse(viewModel.canSubmitResponse)
        XCTAssertEqual(viewModel.selectedOptionID, research.poll.options[1].id)
        XCTAssertEqual(answered, ["podcast_discovery"])
    }

    /// An account answers once, whatever the UI does with a second tap.
    func testAnsweringTwiceKeepsTheFirstAnswer() throws {
        let viewModel = WhatsNewMessageViewModel(message: try researchMessage())
        let research = try XCTUnwrap(viewModel.research)
        var answered: [String] = []
        viewModel.onRespond = { _, option in answered.append(option.pollOptionKey) }

        viewModel.select(research.poll.options[0])
        viewModel.submitResponse()
        viewModel.select(research.poll.options[1])
        viewModel.submitResponse()

        XCTAssertEqual(viewModel.selectedOptionID, research.poll.options[0].id, "The answered poll can't be picked over")
        XCTAssertEqual(answered, ["up_next_controls"], "The second answer is neither reported nor recorded")
    }

    /// Sync records that the account answered, not what it answered, so a poll answered on another
    /// device comes back closed with nothing to point at.
    func testAPollAnsweredElsewhereIsClosedWithNoOptionSelected() throws {
        let viewModel = WhatsNewMessageViewModel(message: try researchMessage(), hasResponded: true)
        let research = try XCTUnwrap(viewModel.research)

        XCTAssertTrue(viewModel.hasResponded)
        XCTAssertNil(viewModel.selectedOptionID)
        XCTAssertFalse(viewModel.canSubmitResponse)

        viewModel.select(research.poll.options[0])

        XCTAssertNil(viewModel.selectedOptionID, "A poll that's already been answered can't be answered again")
    }

    /// A poll is titled by the question it asks, so its bar names the kind of message instead of
    /// repeating a title that isn't on the screen.
    func testAPollIsTitledByItsCategoryAndAStandardMessageByItsOwnTitle() throws {
        XCTAssertEqual(WhatsNewMessageViewModel(message: try researchMessage()).navigationTitle, L10n.whatsNewCategoryResearch)
        XCTAssertEqual(WhatsNewMessageViewModel(message: try message(pages: onePage)).navigationTitle, "Introducing episode transcripts")
    }

    // MARK: - Helpers

    private let onePage = """
    [{
      "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "Episode transcript open beside the player" },
      "heading": "Read along while you listen",
      "description": "Search a transcript and follow the conversation."
    }]
    """

    private func page(heading: String, action: String? = nil) -> String {
        """
        {
          "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
          "heading": "\(heading)",
          "description": "…"\(action.map { ",\n  \"action\": \($0)" } ?? "")
        }
        """
    }

    /// A message whose title is fixed and whose pages are whatever the test is about.
    private func message(pages: String) throws -> WhatsNewMessage {
        try decoded("""
        {
          "id": "550e8400-e29b-41d4-a716-446655440001",
          "type": "new_feature",
          "publishedAt": "2026-08-17T08:00:00Z",
          "targeting": { "audiences": [] },
          "title": "Introducing episode transcripts",
          "pages": \(pages)
        }
        """)
    }

    private func researchMessage() throws -> WhatsNewMessage {
        try decoded("""
        {
          "id": "550e8400-e29b-41d4-a716-446655440003",
          "type": "research",
          "publishedAt": "2026-08-12T09:00:00Z",
          "targeting": { "audiences": [] },
          "title": "Help shape the player",
          "description": "Which improvement would make the biggest difference?",
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
        """)
    }

    private func decoded(_ json: String) throws -> WhatsNewMessage {
        let catalog = """
        { "schemaVersion": 1, "messages": [\(json)] }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try XCTUnwrap(decoder.decode(WhatsNewCatalog.self, from: Data(catalog.utf8)).messages.first)
    }
}

private extension WhatsNewMessageViewModel {
    var pages: [Page] {
        guard case .pages(let pages) = content else { return [] }
        return pages
    }

    var research: WhatsNewResearch? {
        guard case .research(let research) = content else { return nil }
        return research
    }
}
