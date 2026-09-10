import Foundation
import PocketCastsServer
import PocketCastsUtils

/// One What's New message, reduced to what the detail screen can actually draw.
struct WhatsNewMessageViewModel {
    /// The message's own title, falling back to the one its feed row uses.
    let title: String

    /// The pages the pager shows, in the order the catalog published them.
    let pages: [Page]

    /// A page of a message and the blocks it's made of.
    struct Page: Identifiable {
        /// The page's position, which is all the contract gives a page to be identified by.
        let id: Int

        /// The blocks that scroll, in the order the catalog published them.
        let blocks: [WhatsNewBlock]

        /// The page's calls to action, which sit at the bottom of the page rather than scrolling
        /// away with the content they were published between.
        let actions: [WhatsNewAction]

        /// The poll the page asks, which is answered by a button pinned beside those actions.
        let poll: WhatsNewPoll?
    }

    init(message: WhatsNewMessage) {
        title = message.content.title ?? message.summary.title
        pages = message.content.pages
            .map { Self.supportedBlocks(in: $0.blocks) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { offset, blocks in
                Page(id: offset,
                     blocks: blocks.filter { $0.action == nil },
                     actions: blocks.compactMap(\.action),
                     poll: blocks.compactMap(\.poll).first)
            }
    }

    /// Whether the app has anything to draw for the message.
    ///
    /// A page whose blocks are all dropped is dropped with them, and a message left with no pages
    /// would open onto an empty pager, so the feed leaves it out rather than showing a row that
    /// goes nowhere.
    static func canRender(_ message: WhatsNewMessage) -> Bool {
        !WhatsNewMessageViewModel(message: message).pages.isEmpty
    }

    /// The blocks of a page the app can draw, in the order they were published.
    ///
    /// An action the allowlist rejects would render as a button that does nothing, so it's dropped.
    /// So is a second poll: a page's answers are sent by the one button pinned beneath it, which
    /// leaves it room for one poll's worth of questions.
    private static func supportedBlocks(in blocks: [WhatsNewBlock]) -> [WhatsNewBlock] {
        var hasPoll = false

        return blocks.filter { block in
            switch block {
            case .action(let action):
                guard WhatsNewLink(url: action.url) != nil else {
                    FileLog.shared.addMessage("What's New: dropping an action pointing at an unsupported URL: \(action.url.absoluteString)")
                    return false
                }
                return true
            case .poll(let poll):
                guard !hasPoll else {
                    FileLog.shared.addMessage("What's New: dropping poll \(poll.pollId), which follows another one on the same page")
                    return false
                }
                hasPoll = true
                return true
            default:
                return true
            }
        }
    }
}

private extension WhatsNewBlock {
    var action: WhatsNewAction? {
        guard case .action(let action) = self else { return nil }
        return action
    }

    var poll: WhatsNewPoll? {
        guard case .poll(let poll) = self else { return nil }
        return poll
    }
}
