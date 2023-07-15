import Foundation

/// A bookmark that represents a position in time within an episode
public struct Bookmark: Hashable {
    public let uuid: String
    public let title: String
    public let time: TimeInterval

    public let created: Date
    public let modified: Date

    public let episodeUuid: String
    public let podcastUuid: String?

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

// MARK: - Identifiable
extension Bookmark: Identifiable {
    public var id: String { uuid }
}

extension Bookmark {
    public static let preview = Bookmark(uuid: "bookmark",
                                         title: "Interesting Part",
                                         time: 3600,
                                         created: Date(),
                                         modified: Date(),
                                         episodeUuid: "episode",
                                         podcastUuid: "podcast")
}
