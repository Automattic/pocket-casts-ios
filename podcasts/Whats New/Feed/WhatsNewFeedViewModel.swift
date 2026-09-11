import Foundation
import PocketCastsServer

/// A single row of the What's New feed.
///
/// The catalog gives a message one title and a type. Everything else the row shows — what the type
/// is called, the icon beside it — comes from this app rather than from the feed it's drawn from.
struct WhatsNewFeedItem: Identifiable, Hashable {
    let id: String
    let type: WhatsNewMessageType
    let title: String
    let publishedAt: Date
    var isUnread: Bool

    var label: String {
        type.categoryLabel
    }

    init(message: WhatsNewMessage, isUnread: Bool) {
        id = message.id
        type = message.type
        title = message.title
        publishedAt = message.publishedAt
        self.isUnread = isUnread
    }
}

/// The messages the What's New feed shows, most recently published first.
///
/// A message this build can't make sense of never decodes, and one that isn't aimed at this user
/// never reaches the list, so no row opens onto an empty screen — or marks itself read on the way
/// there.
@MainActor
final class WhatsNewFeedViewModel: ObservableObject {
    enum State {
        case loading
        case loaded
        case failed
    }

    @Published private(set) var items: [WhatsNewFeedItem] = []
    @Published private(set) var state: State

    /// Called with the message a tapped row belongs to.
    var onSelect: ((WhatsNewMessage) -> Void)?

    private var messages: [WhatsNewMessage] = []
    private var readMessageIDs: Set<String>
    private var respondedPollIDs: Set<String> = []
    private let manager: WhatsNewManager?
    private let targeting: WhatsNewMessageFilter

    init(manager: WhatsNewManager = .shared, targeting: WhatsNewMessageFilter = .current) {
        self.manager = manager
        self.targeting = targeting
        readMessageIDs = []
        state = manager.catalog == nil ? .loading : .loaded
        show(manager.catalog?.messages ?? [])
    }

    init(messages: [WhatsNewMessage], readMessageIDs: Set<String> = [], targeting: WhatsNewMessageFilter = .current) {
        manager = nil
        self.targeting = targeting
        self.readMessageIDs = readMessageIDs
        state = .loaded
        show(messages)
    }

    /// Shows what the manager has, waiting on the refresh it starts when that copy has aged out.
    ///
    /// Fails only when the manager has no catalog at all: a refresh that fails over a cached copy
    /// still has messages to show. A load cancelled by the feed going away leaves the state as it
    /// was, so the next one picks up from there.
    func load() async {
        guard let manager else { return }
        await manager.refreshIfNeeded().value
        showCatalog(of: manager)
    }

    /// Fetches the catalog again however recently it was fetched, for pulling to refresh the feed.
    func refresh() async {
        guard let manager else { return }
        await manager.refresh().value
        showCatalog(of: manager)
    }

    /// Loads the catalog again after it failed, showing progress while it does.
    func retry() async {
        state = .loading
        await load()
    }

    var hasUnreadItems: Bool {
        items.contains { $0.isUnread }
    }

    func select(_ item: WhatsNewFeedItem) {
        markAsRead(item.id)

        guard let message = messages.first(where: { $0.id == item.id }) else { return }
        onSelect?(message)
    }

    func markAllAsRead() {
        readMessageIDs.formUnion(items.map(\.id))
        for index in items.indices {
            items[index].isUnread = false
        }
    }

    /// Whether the poll the message asks, if it asks one, has already been answered.
    ///
    /// Answers stay put for as long as the feed is around, so a poll answered and backed out of
    /// doesn't offer itself again when the message is opened a second time.
    func hasResponded(to message: WhatsNewMessage) -> Bool {
        guard let poll = message.content.research?.poll else { return false }
        return respondedPollIDs.contains(poll.pollId)
    }

    func markAsResponded(to poll: WhatsNewPoll) {
        respondedPollIDs.insert(poll.pollId)
    }

    private func markAsRead(_ id: WhatsNewFeedItem.ID) {
        readMessageIDs.insert(id)

        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isUnread = false
    }

    private func showCatalog(of manager: WhatsNewManager) {
        guard !Task.isCancelled else { return }
        guard let catalog = manager.catalog else {
            state = .failed
            return
        }
        show(catalog.messages)
        state = .loaded
    }

    private func show(_ messages: [WhatsNewMessage]) {
        self.messages = messages
            .filter { targeting.includes($0) }
            .sorted { $0.publishedAt > $1.publishedAt }
        items = self.messages.map { WhatsNewFeedItem(message: $0, isUnread: !readMessageIDs.contains($0.id)) }
    }
}
