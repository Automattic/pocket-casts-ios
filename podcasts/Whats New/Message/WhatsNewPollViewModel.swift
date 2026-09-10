import Foundation
import PocketCastsServer
import PocketCastsUtils

/// The answers given to the poll on a page, and how far sending them has got.
///
/// Every page keeps one of these whether or not it asks anything, so the blocks that scroll and the
/// button pinned beneath them are always looking at the same object. A page without a poll has
/// nothing to ask and nothing to send.
@MainActor
final class WhatsNewPollViewModel: ObservableObject {
    enum State: Equatable {
        /// Waiting on answers, or holding answers that haven't been sent yet.
        case answering

        /// The answers are on their way.
        case sending

        /// The answers were accepted.
        case sent

        /// The answers didn't get through, and can be sent again.
        case failed
    }

    let poll: WhatsNewPoll?

    @Published private(set) var state: State = .answering

    /// The options chosen for each question, keyed by question ID.
    @Published private(set) var selectedOptionIDs: [String: Set<String>] = [:]

    private let task: WhatsNewPollTask

    init(poll: WhatsNewPoll?, task: WhatsNewPollTask = WhatsNewPollTask()) {
        self.poll = poll
        self.task = task
    }

    var questions: [WhatsNewPoll.Question] {
        poll?.questions ?? []
    }

    /// Whether every question has been answered, which is what the poll asks for before it can be sent.
    var isComplete: Bool {
        !questions.isEmpty && questions.allSatisfy { !selectedOptionIDs[$0.id, default: []].isEmpty }
    }

    /// Whether the poll still takes answers, which it stops doing once they're on their way.
    var isEditable: Bool {
        state == .answering || state == .failed
    }

    func isSelected(_ option: WhatsNewPoll.Option, in question: WhatsNewPoll.Question) -> Bool {
        selectedOptionIDs[question.id, default: []].contains(option.id)
    }

    /// Chooses an option, or takes it back.
    ///
    /// A question that takes a single answer replaces the one it already has, so tapping down the
    /// list moves the choice rather than piling answers up.
    func toggle(_ option: WhatsNewPoll.Option, in question: WhatsNewPoll.Question) {
        guard isEditable else { return }

        var selected = selectedOptionIDs[question.id, default: []]
        switch (question.allowsMultipleAnswers, selected.contains(option.id)) {
        case (true, true):
            selected.remove(option.id)
        case (true, false):
            selected.insert(option.id)
        case (false, true):
            selected = []
        case (false, false):
            selected = [option.id]
        }
        selectedOptionIDs[question.id] = selected

        // Changing an answer after a failed attempt puts the button back to the one that sends it.
        if state == .failed {
            state = .answering
        }
    }

    func submit() async {
        guard let poll, isComplete, isEditable else { return }

        state = .sending
        do {
            try await task.submit(response(for: poll))
            state = .sent
        } catch {
            FileLog.shared.addMessage("What's New: failed to send the answers to poll \(poll.pollId): \(error.localizedDescription)")
            state = .failed
        }
    }

    /// The answers in the order the poll published its questions and options, rather than the order
    /// they happened to be tapped in.
    private func response(for poll: WhatsNewPoll) -> WhatsNewPollResponse {
        let answers = poll.questions.map { question in
            let selected = selectedOptionIDs[question.id, default: []]
            return WhatsNewPollResponse.Answer(questionId: question.id,
                                               optionIds: question.options.map(\.id).filter(selected.contains))
        }
        return WhatsNewPollResponse(pollId: poll.pollId, answers: answers)
    }
}
