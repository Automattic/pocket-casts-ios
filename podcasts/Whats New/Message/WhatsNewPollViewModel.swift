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

    init(poll: WhatsNewPoll?) {
        self.poll = poll
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

    /// TODO: send the answers — a poll response has nowhere to go yet: its destination, whether
    /// it's authenticated or anonymous, and whether sending it twice replaces the first answer are
    /// all undecided. Until then this records the answers in the log and reports success, so the
    /// screen can be exercised without inventing an endpoint.
    func submit() async {
        guard let poll, isComplete, isEditable else { return }

        state = .sending

        let answers = poll.questions
            .map { question in
                let selected = selectedOptionIDs[question.id, default: []]
                let chosen = question.options.map(\.id).filter(selected.contains)
                return "\(question.id)=\(chosen.joined(separator: ","))"
            }
            .joined(separator: " ")
        FileLog.shared.addMessage("What's New: poll \(poll.pollId) answered with \(answers). Not sent: no submission endpoint yet")

        try? await Task.sleep(for: .seconds(1))
        state = .sent
    }
}
