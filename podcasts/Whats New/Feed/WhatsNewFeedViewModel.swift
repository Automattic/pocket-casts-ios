import Foundation
import PocketCastsServer

/// A single row of the What's New feed.
struct WhatsNewFeedItem: Identifiable, Hashable {
    let id: String
    let type: WhatsNewMessageType
    let label: String?
    let title: String
    let publishedAt: Date
    let imageURL: URL?
    var isUnread: Bool

    init(message: WhatsNewMessage, isUnread: Bool) {
        id = message.id
        type = message.type
        label = message.summary.label
        title = message.summary.title
        publishedAt = message.publishedAt
        imageURL = message.summary.imageUrl
        self.isUnread = isUnread
    }
}

/// The messages the What's New feed shows, most recently published first.
///
/// A message this build has nothing to draw never reaches the list, so no row opens onto an empty
/// screen — or marks itself read on the way there.
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
    private let catalogTask: WhatsNewCatalogTask?

    init(catalogTask: WhatsNewCatalogTask = WhatsNewCatalogTask()) {
        self.catalogTask = catalogTask
        readMessageIDs = []
        state = .loading
    }

    init(messages: [WhatsNewMessage], readMessageIDs: Set<String> = []) {
        catalogTask = nil
        self.readMessageIDs = readMessageIDs
        state = .loaded
        show(messages)
    }

    /// Fills the feed in from the published catalog, or from the cached copy when it can't be reached.
    ///
    /// Fails only when there's no cached copy to fall back to. A load cancelled by the feed going
    /// away leaves the state as it was, so the next one picks up from there.
    func load() async {
        guard let catalogTask else { return }
        do {
            let catalog = try await catalogTask.catalog()
            show(catalog.messages)
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed
        }
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

    private func markAsRead(_ id: WhatsNewFeedItem.ID) {
        readMessageIDs.insert(id)

        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isUnread = false
    }

    private func show(_ messages: [WhatsNewMessage]) {
        self.messages = messages
            .filter(WhatsNewMessageViewModel.canRender)
            .sorted { $0.publishedAt > $1.publishedAt }
        items = self.messages.map { WhatsNewFeedItem(message: $0, isUnread: !readMessageIDs.contains($0.id)) }
    }
}
