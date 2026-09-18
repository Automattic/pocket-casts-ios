import Combine
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
    private var cancellables = Set<AnyCancellable>()

    /// A feed of the manager's catalog, which records what it lists, what's read and which polls are
    /// answered through the manager, and follows the manager's read state wherever else it changes.
    init(manager: WhatsNewManager = .shared, targeting: WhatsNewMessageFilter = .current) {
        self.manager = manager
        self.targeting = targeting
        readMessageIDs = manager.readState.readMessageIDs
        respondedPollIDs = manager.readState.respondedPollIDs
        state = manager.catalog == nil ? .loading : .loaded
        show(manager.catalog?.messages ?? [])

        manager.$readState
            .dropFirst()
            .sink { [weak self] readState in
                self?.readMessageIDs = readState.readMessageIDs
                self?.respondedPollIDs = readState.respondedPollIDs
                self?.updateItems()
            }
            .store(in: &cancellables)
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
        markAsRead([item.id])

        guard let message = messages.first(where: { $0.id == item.id }) else { return }
        onSelect?(message)
    }

    /// Marks every message the feed shows read, and none of the ones it leaves out.
    func markAllAsRead() {
        markAsRead(items.map(\.id))
    }

    /// Whether the poll the message asks, if it asks one, has already been answered.
    ///
    /// Answers are kept with the read state, so a poll doesn't offer itself again however many times
    /// the message is opened.
    func hasResponded(to message: WhatsNewMessage) -> Bool {
        guard let poll = message.content.research?.poll else { return false }
        return respondedPollIDs.contains(poll.pollId)
    }

    func markAsResponded(to poll: WhatsNewPoll) {
        respondedPollIDs.insert(poll.pollId)
        manager?.markAsResponded(toPoll: poll.pollId)
    }

    /// The messages the feed lists out of `messages`, most recently published first.
    static func feedMessages(from messages: [WhatsNewMessage], targeting: WhatsNewMessageFilter) -> [WhatsNewMessage] {
        messages
            .filter { targeting.includes($0) }
            .sorted { $0.publishedAt > $1.publishedAt }
    }

    private func markAsRead(_ ids: [WhatsNewFeedItem.ID]) {
        readMessageIDs.formUnion(ids)
        manager?.markAsRead(ids)
        updateItems()
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
        self.messages = Self.feedMessages(from: messages, targeting: targeting)
        manager?.markAsListed(self.messages.map(\.id))
        updateItems()
    }

    private func updateItems() {
        let items = messages.map { WhatsNewFeedItem(message: $0, isUnread: !readMessageIDs.contains($0.id)) }
        guard items != self.items else { return }
        self.items = items
    }
}
