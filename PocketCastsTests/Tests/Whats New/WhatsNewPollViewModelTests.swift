import PocketCastsServer
import XCTest

@testable import podcasts

@MainActor
final class WhatsNewPollViewModelTests: XCTestCase {
    /// A poll can't be sent until every question it asks has an answer.
    func testEveryQuestionHasToBeAnsweredBeforeThePollCanBeSent() throws {
        let viewModel = try viewModel(poll: twoQuestions)
        let (first, second) = (viewModel.questions[0], viewModel.questions[1])

        XCTAssertFalse(viewModel.isComplete)

        viewModel.toggle(first.options[0], in: first)
        XCTAssertFalse(viewModel.isComplete)

        viewModel.toggle(second.options[0], in: second)
        XCTAssertTrue(viewModel.isComplete)
    }

    /// Tapping down the list of a single-answer question moves the choice rather than piling
    /// answers up.
    func testChoosingAnotherOptionReplacesASingleAnswer() throws {
        let viewModel = try viewModel(poll: twoQuestions)
        let question = viewModel.questions[0]

        viewModel.toggle(question.options[0], in: question)
        viewModel.toggle(question.options[1], in: question)

        XCTAssertFalse(viewModel.isSelected(question.options[0], in: question))
        XCTAssertTrue(viewModel.isSelected(question.options[1], in: question))
    }

    func testTappingTheChosenOptionTakesItBack() throws {
        let viewModel = try viewModel(poll: twoQuestions)
        let question = viewModel.questions[0]

        viewModel.toggle(question.options[0], in: question)
        viewModel.toggle(question.options[0], in: question)

        XCTAssertFalse(viewModel.isSelected(question.options[0], in: question))
        XCTAssertFalse(viewModel.isComplete)
    }

    func testAQuestionThatTakesMoreThanOneAnswerKeepsThemAll() throws {
        let viewModel = try viewModel(poll: twoQuestions)
        let question = viewModel.questions[1]

        viewModel.toggle(question.options[0], in: question)
        viewModel.toggle(question.options[1], in: question)

        XCTAssertTrue(viewModel.isSelected(question.options[0], in: question))
        XCTAssertTrue(viewModel.isSelected(question.options[1], in: question))
    }

    func testAnsweringStopsOnceTheAnswersHaveBeenSent() async throws {
        let viewModel = try viewModel(poll: twoQuestions)
        let (first, second) = (viewModel.questions[0], viewModel.questions[1])

        viewModel.toggle(first.options[0], in: first)
        viewModel.toggle(second.options[0], in: second)
        await viewModel.submit()

        XCTAssertEqual(viewModel.state, .sent)
        XCTAssertFalse(viewModel.isEditable)

        viewModel.toggle(first.options[1], in: first)
        XCTAssertTrue(viewModel.isSelected(first.options[0], in: first), "The answers stay as they were sent")
    }

    /// The button is disabled until every question is answered, but a stray tap shouldn't send a
    /// half-finished poll either.
    func testAHalfAnsweredPollIsntSent() async throws {
        let viewModel = try viewModel(poll: twoQuestions)
        let question = viewModel.questions[0]

        viewModel.toggle(question.options[0], in: question)
        await viewModel.submit()

        XCTAssertEqual(viewModel.state, .answering)
    }

    /// A page without a poll gets a view model all the same, and it has nothing to send.
    func testAPageWithoutAPollHasNothingToAsk() async {
        let viewModel = WhatsNewPollViewModel(poll: nil)

        XCTAssertTrue(viewModel.questions.isEmpty)
        XCTAssertFalse(viewModel.isComplete)

        await viewModel.submit()
        XCTAssertEqual(viewModel.state, .answering)
    }

    // MARK: - Helpers

    private var twoQuestions: String {
        """
        {
          "type": "poll",
          "pollId": "01K2Y2S65F22TQZQJVNAEXQKHT",
          "questions": [
            {
              "id": "01K2Y3B2XKQ4G9TP7NMRV5CDW0",
              "text": "What social features would you be interested in?",
              "options": [
                { "id": "01K2Y2VJSSTJ66NPVQPM5YWFD1", "label": "Public profiles" },
                { "id": "01K2Y2W4D16N3EEWXQS7YWH610", "label": "Activity feed" }
              ]
            },
            {
              "id": "01K2Y3D4KVN6RQ8ZTWH3PB5YXC",
              "text": "Which would you turn on first?",
              "allowsMultipleAnswers": true,
              "options": [
                { "id": "01K2Y3DPB8ZW5QRTH7NKM2XVJ6", "label": "Sharing what you're listening to" },
                { "id": "01K2Y3E5R2QMT9WKHZ6NPB4XDC", "label": "Seeing what your friends play" }
              ]
            }
          ]
        }
        """
    }

    private func viewModel(poll json: String) throws -> WhatsNewPollViewModel {
        WhatsNewPollViewModel(poll: try XCTUnwrap(JSONDecoder().decode(WhatsNewPoll.self, from: Data(json.utf8))))
    }
}
