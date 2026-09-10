import Foundation
@testable import PocketCastsServer
import XCTest

final class WhatsNewPollTests: XCTestCase {
    /// The shape the implementation plan publishes: one question, carried on the block itself.
    func testDecodesASingleQuestionCarriedOnTheBlock() throws {
        let poll = try decodedPoll("""
        {
          "type": "poll",
          "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
          "question": "What should we improve next?",
          "options": [
            { "id": "01K2Y2VJSSTJ66NPVQPM5YWFD1", "label": "Up Next controls" },
            { "id": "01K2Y2W4D16N3EEWXQS7YWH610", "label": "Podcast discovery" }
          ]
        }
        """)

        XCTAssertEqual(poll.pollId, "01K2Y2S65F22TQZQJVNAEXQKHT")
        XCTAssertEqual(poll.questions.count, 1)

        let question = try XCTUnwrap(poll.questions.first)
        XCTAssertEqual(question.text, "What should we improve next?")
        XCTAssertEqual(question.id, poll.pollId, "A question published without an ID of its own answers to the poll's")
        XCTAssertFalse(question.allowsMultipleAnswers)
        XCTAssertEqual(question.options.map(\.label), ["Up Next controls", "Podcast discovery"])
        XCTAssertEqual(question.options.map(\.id), ["01K2Y2VJSSTJ66NPVQPM5YWFD1", "01K2Y2W4D16N3EEWXQS7YWH610"])
    }

    func testDecodesAPollThatAsksMoreThanOneQuestion() throws {
        let poll = try decodedPoll("""
        {
          "type": "poll",
          "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
          "questions": [
            {
              "id": "01K2Y3B2XKQ4G9TP7NMRV5CDW0",
              "text": "How often would you use them?",
              "options": [{ "id": "01K2Y3BJ6ZR8YH2QW4KFT7NAD5", "label": "Every day" }]
            },
            {
              "id": "01K2Y3D4KVN6RQ8ZTWH3PB5YXC",
              "text": "Which would you turn on first?",
              "allowsMultipleAnswers": true,
              "options": [{ "id": "01K2Y3DPB8ZW5QRTH7NKM2XVJ6", "label": "Sharing what you're listening to" }]
            }
          ]
        }
        """)

        XCTAssertEqual(poll.questions.map(\.text), ["How often would you use them?", "Which would you turn on first?"])
        XCTAssertEqual(poll.questions.map(\.id), ["01K2Y3B2XKQ4G9TP7NMRV5CDW0", "01K2Y3D4KVN6RQ8ZTWH3PB5YXC"])
        XCTAssertEqual(poll.questions.map(\.allowsMultipleAnswers), [false, true])
    }

    /// A question with nothing to choose between can't be answered, and one that can't be answered
    /// would leave the poll's button disabled forever.
    func testDropsQuestionsWithNoOptions() throws {
        let page = try decodedPage("""
        {
          "blocks": [
            {
              "type": "poll",
              "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
              "questions": [
                { "id": "01K2Y3B2XKQ4G9TP7NMRV5CDW0", "text": "Nothing to pick", "options": [] },
                {
                  "id": "01K2Y3D4KVN6RQ8ZTWH3PB5YXC",
                  "text": "Which would you turn on first?",
                  "options": [{ "id": "01K2Y3DPB8ZW5QRTH7NKM2XVJ6", "label": "Sharing what you're listening to" }]
                }
              ]
            }
          ]
        }
        """)

        guard case .poll(let poll) = try XCTUnwrap(page.blocks.first) else {
            XCTFail("Expected a poll block, got \(page.blocks)")
            return
        }
        XCTAssertEqual(poll.questions.map(\.text), ["Which would you turn on first?"])
    }

    func testDropsAPollLeftWithNothingToAsk() throws {
        let page = try decodedPage("""
        {
          "blocks": [
            { "type": "poll", "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT", "question": "What next?", "options": [] },
            { "type": "paragraph", "content": "The survey takes about two minutes." }
          ]
        }
        """)

        XCTAssertEqual(page.blocks.count, 1, "The poll with no options is dropped, the paragraph beside it is kept")
        guard case .paragraph = try XCTUnwrap(page.blocks.first) else {
            XCTFail("Expected a paragraph block, got \(page.blocks)")
            return
        }
    }

    func testDropsAPollPublishedWithoutAnID() throws {
        let page = try decodedPage("""
        {
          "blocks": [
            {
              "type": "poll",
              "question": "What next?",
              "options": [{ "id": "01K2Y2VJSSTJ66NPVQPM5YWFD1", "label": "Up Next controls" }]
            },
            { "type": "paragraph", "content": "The survey takes about two minutes." }
          ]
        }
        """)

        XCTAssertEqual(page.blocks.count, 1, "There's nothing to record an answer against, so the poll is dropped")
    }

    // MARK: - Helpers

    private func decodedPoll(_ json: String) throws -> WhatsNewPoll {
        let block = try WhatsNewCatalog.decoder.decode(WhatsNewBlock.self, from: Data(json.utf8))
        guard case .poll(let poll) = block else {
            throw XCTSkip("Expected a poll block, got \(block)")
        }
        return poll
    }

    private func decodedPage(_ json: String) throws -> WhatsNewPage {
        try WhatsNewCatalog.decoder.decode(WhatsNewPage.self, from: Data(json.utf8))
    }
}
