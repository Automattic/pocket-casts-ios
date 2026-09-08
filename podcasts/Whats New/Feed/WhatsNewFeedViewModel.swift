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
@MainActor
final class WhatsNewFeedViewModel: ObservableObject {
    @Published private(set) var items: [WhatsNewFeedItem]

    /// Called with the message a tapped row belongs to.
    var onSelect: ((WhatsNewMessage) -> Void)?

    private let messages: [WhatsNewMessage]

    init(messages: [WhatsNewMessage], readMessageIDs: Set<String> = []) {
        self.messages = messages.sorted { $0.publishedAt > $1.publishedAt }
        items = self.messages.map { WhatsNewFeedItem(message: $0, isUnread: !readMessageIDs.contains($0.id)) }
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
        for index in items.indices {
            items[index].isUnread = false
        }
    }

    private func markAsRead(_ id: WhatsNewFeedItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isUnread = false
    }
}
