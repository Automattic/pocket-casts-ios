import Foundation

/// The network list a podcast belongs to, as reported by the podcast refresh payload.
///
/// It's only kept in memory on the `Podcast` it came from, it isn't persisted.
public struct PodcastNetworkList: Equatable, Hashable, Sendable {
    public let listId: String
    public let source: String

    public init(listId: String, source: String) {
        self.listId = listId
        self.source = source
    }
}
