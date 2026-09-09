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
    }

    init(message: WhatsNewMessage) {
        title = message.content.title ?? message.summary.title
        pages = message.content.pages
            .map { $0.blocks.filter(Self.isSupported) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { Page(id: $0.offset, blocks: $0.element.filter { $0.action == nil }, actions: $0.element.compactMap(\.action)) }
    }

    /// Whether the app can draw the block, which for an action means having somewhere to send the
    /// user: an action the allowlist rejects would otherwise render as a button that does nothing.
    private static func isSupported(_ block: WhatsNewBlock) -> Bool {
        guard case .action(let action) = block else { return true }
        guard WhatsNewLink(url: action.url) != nil else {
            FileLog.shared.addMessage("What's New: dropping an action pointing at an unsupported URL: \(action.url.absoluteString)")
            return false
        }
        return true
    }
}

private extension WhatsNewBlock {
    var action: WhatsNewAction? {
        guard case .action(let action) = self else { return nil }
        return action
    }
}
