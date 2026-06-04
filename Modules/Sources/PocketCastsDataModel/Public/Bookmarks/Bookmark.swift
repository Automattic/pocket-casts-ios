import Foundation
import SwiftUI

/// A bookmark that represents a position in time within an episode
public struct Bookmark: Hashable {
    public let uuid: String
    public let title: String
    public let time: TimeInterval

    public let created: Date

    public let episodeUuid: String
    public let podcastUuid: String?

    public var episode: BaseEpisode? = nil
    public var podcast: Podcast? = nil

    public var transcriptText: String? = nil
    public var transcriptStartTime: TimeInterval? = nil
    public var transcriptEndTime: TimeInterval? = nil

    // For syncing
    public var titleModified: Date? = nil
    public var deletedModified: Date? = nil
    public var deleted: Bool = false

    public var hasTranscriptSelection: Bool {
        transcriptText != nil && transcriptStartTime != nil && transcriptEndTime != nil
    }

    // `BaseEpisode` and `Podcast` don't conform to Hashable, so instead we implement it manually to ignore those properties
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(title)
        hasher.combine(time)
        hasher.combine(created)
        hasher.combine(episodeUuid)
        hasher.combine(podcastUuid)
        hasher.combine(transcriptText)
        hasher.combine(transcriptStartTime)
        hasher.combine(transcriptEndTime)
        hasher.combine(titleModified)
        hasher.combine(deletedModified)
    }

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

// MARK: - Public Init

extension Bookmark {
    public init(uuid: String, title: String, time: TimeInterval, created: Date, episodeUuid: String, podcastUuid: String?) {
        self.uuid = uuid
        self.title = title
        self.time = time
        self.created = created
        self.episodeUuid = episodeUuid
        self.podcastUuid = podcastUuid
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
                 episodeUuid: "episode",
                 podcastUuid: "podcast")
    }
}
