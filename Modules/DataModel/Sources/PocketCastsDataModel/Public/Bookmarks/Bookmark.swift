import FMDB
import PocketCastsUtils

/// A bookmark that represents a position in time within an episode
public struct Bookmark {
    public let uuid: String
    public let createdDate: Date
    public let time: TimeInterval
    public let title: String?
    public let episodeUuid: String
    public let podcastUuid: String?
}

// MARK: - Identifiable
extension Bookmark: Identifiable {
    public var id: String { uuid }
}
