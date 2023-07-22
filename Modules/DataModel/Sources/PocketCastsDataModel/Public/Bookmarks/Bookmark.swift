import Foundation
import SwiftUI

/// A bookmark that represents a position in time within an episode
public struct Bookmark: Hashable {
    public let uuid: String
    public let title: String
    public let time: TimeInterval

    public let created: Date
    public let modified: Date

    public let episodeUuid: String
    public let podcastUuid: String?

    public var episode: BaseEpisode? = nil
    public var podcast: Podcast? = nil

    // `BaseEpisode` and `Podcast` don't conform to Hashable, so instead we implement it manually to ignore those properties
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(title)
        hasher.combine(time)
        hasher.combine(created)
        hasher.combine(episodeUuid)
        hasher.combine(podcastUuid)
    }

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

// MARK: - Identifiable

extension Bookmark: Identifiable {
    public var id: String { uuid }
}

// MARK: - Preview Data

extension PreviewProvider {
    public static func previewBookmark(title: String, time: TimeInterval, created: Date) -> Bookmark {
        Bookmark(uuid: UUID().uuidString,
                 title: title,
                 time: time,
                 created: created,
                 modified: Date(),
                 episodeUuid: "episode",
                 podcastUuid: "podcast")
    }
}
