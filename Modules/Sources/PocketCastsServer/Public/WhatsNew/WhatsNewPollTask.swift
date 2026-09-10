import Foundation
import PocketCastsUtils

/// The answers a reader gave to a poll, in the order the poll published its questions.
public struct WhatsNewPollResponse: Hashable {
    public let pollId: String
    public let answers: [Answer]

    public init(pollId: String, answers: [Answer]) {
        self.pollId = pollId
        self.answers = answers
    }

    /// The options chosen for a single question.
    public struct Answer: Hashable {
        public let questionId: String
        public let optionIds: [String]

        public init(questionId: String, optionIds: [String]) {
            self.questionId = questionId
            self.optionIds = optionIds
        }
    }
}

/// Sends a reader's answers to a What's New poll.
public struct WhatsNewPollTask {
    public init() {}

    /// TODO: submit — the implementation plan leaves a poll response's transport undefined: its
    /// destination, whether it's authenticated or anonymous, how an answer is validated, whether
    /// sending it twice is idempotent or a second answer replaces the first, how long it's kept,
    /// and which analytics it reports. Until those are decided this records the answers in the log
    /// and reports success, so the screen can be exercised without inventing an endpoint.
    public func submit(_ response: WhatsNewPollResponse) async throws {
        let answers = response.answers
            .map { "\($0.questionId)=\($0.optionIds.joined(separator: ","))" }
            .joined(separator: " ")
        FileLog.shared.addMessage("What's New: poll \(response.pollId) answered with \(answers). Not sent: no submission endpoint yet")
    }
}
