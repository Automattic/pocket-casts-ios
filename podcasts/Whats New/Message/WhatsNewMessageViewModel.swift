import Foundation
import PocketCastsServer

/// One What's New message, reduced to what the detail screen draws.
///
/// The catalog publishes a small set of curated layouts rather than free-form content, so there's
/// nothing here to decide beyond which of them the message asked for and whether this build knows
/// what its actions mean.
@MainActor
final class WhatsNewMessageViewModel: ObservableObject {
    /// The one title the message is known by, the same one its feed row shows.
    let title: String

    let content: Content

    /// Which layout the message is drawn in, which its type decides.
    enum Content {
        /// The pages the pager shows, in the order the catalog published them.
        case pages([Page])

        /// The single poll a research message is built around.
        case research(Research)
    }

    /// A page of a standard message: an image, what it's about, and at most one thing to do next.
    struct Page: Identifiable {
        /// The page's position, which is all the contract gives a page to be identified by.
        let id: Int

        let image: WhatsNewImage
        let heading: String
        let description: String

        /// What the page offers to do next, left out when its event is one this build doesn't
        /// implement: a button that goes nowhere is worse than no button.
        let action: Action?
    }

    struct Action {
        let label: String
        let event: WhatsNewActionEvent
    }

    struct Research {
        /// What the message says before the question, which not every research message has.
        let description: String?

        let poll: WhatsNewPoll
    }

    /// The option the reader has picked, which isn't sent until they continue, or the one they
    /// answered with. It stays `nil` for a poll answered somewhere this app can't see: the poll is
    /// closed either way, and an answer it can't name is shown as just that.
    @Published private(set) var selectedOptionID: String?

    /// Whether this account has already answered, which closes the poll for good.
    @Published private(set) var hasResponded: Bool

    /// Called with the option the user answered with, once.
    var onRespond: ((WhatsNewPoll, WhatsNewPoll.Option) -> Void)?

    private let messageID: String
    private let messageType: WhatsNewMessageType

    /// What the navigation bar calls the message.
    ///
    /// A poll is titled by the question it asks rather than by its message, so its bar names the
    /// kind of message it is instead of repeating a title that isn't on the screen.
    var navigationTitle: String {
        switch content {
        case .pages: title
        case .research: messageType.categoryLabel
        }
    }

    init(message: WhatsNewMessage, hasResponded: Bool = false) {
        messageID = message.id
        messageType = message.type
        title = message.title
        self.hasResponded = hasResponded

        switch message.content {
        case .pages(let pages):
            content = .pages(pages.enumerated().map { offset, page in
                Page(id: offset,
                     image: page.image,
                     heading: page.heading,
                     description: page.description,
                     action: page.action.flatMap(Action.init(action:)))
            })
        case .research(let research):
            content = .research(Research(description: research.description, poll: research.poll))
        }
    }

    /// Picks an answer, which nothing is told about until the reader continues.
    func select(_ option: WhatsNewPoll.Option) {
        guard !hasResponded else { return }
        selectedOptionID = option.id
    }

    /// Whether there's an answer waiting to be sent.
    var canSubmitResponse: Bool {
        !hasResponded && selectedOption != nil
    }

    /// Answers the poll with the option that's picked, which an account gets to do once.
    ///
    /// The answer is reported to analytics and marked as given separately: whether the event was
    /// delivered has no bearing on the poll being closed, and nothing is reported twice.
    func submitResponse() {
        guard case .research(let research) = content, !hasResponded, let option = selectedOption else { return }

        hasResponded = true

        Analytics.track(.whatsNewPollResponseSubmitted, properties: [
            "message_uuid": messageID,
            "message_type": messageType.rawValue,
            "poll_uuid": research.poll.pollId,
            "poll_key": research.poll.pollKey,
            "option_uuid": option.id,
            "poll_option_key": option.pollOptionKey
        ])

        onRespond?(research.poll, option)
    }

    private var selectedOption: WhatsNewPoll.Option? {
        guard case .research(let research) = content else { return nil }
        return research.poll.options.first { $0.id == selectedOptionID }
    }
}

private extension WhatsNewMessageViewModel.Action {
    init?(action: WhatsNewAction) {
        guard let event = WhatsNewActionEvent(action: action) else { return nil }
        self.init(label: action.label, event: event)
    }
}
