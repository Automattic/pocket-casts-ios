import PocketCastsServer

/// The What's New feed as the rest of the app sees it.
///
/// The feed's rows, the dots on Profile pointing at them, and "Read all" all work from the same
/// list of messages, so a dot never counts a message the feed leaves out.
extension WhatsNewManager {
    /// The catalog's messages the feed lists for this user, most recently published first.
    func feedMessages(targeting: WhatsNewMessageFilter = .current) -> [WhatsNewMessage] {
        WhatsNewFeedViewModel.feedMessages(from: catalog?.messages ?? [], targeting: targeting)
    }

    /// Whether the feed has a message that arrived since the user last opened it, which puts a dot on
    /// the What's New row.
    func hasUnlistedMessages(targeting: WhatsNewMessageFilter = .current) -> Bool {
        feedMessages(targeting: targeting).contains { !readState.isListed($0.id) }
    }

    /// Whether the feed has an unread message the Profile tab hasn't pointed the user at yet, which
    /// puts a dot on the tab.
    func hasUnseenMessages(targeting: WhatsNewMessageFilter = .current) -> Bool {
        feedMessages(targeting: targeting).contains { readState.isUnseen($0.id) }
    }

    /// Takes the dot off the Profile tab until a message arrives that it hasn't pointed at.
    func markFeedAsSeen(targeting: WhatsNewMessageFilter = .current) {
        markAsSeen(feedMessages(targeting: targeting).map(\.id))
    }
}
