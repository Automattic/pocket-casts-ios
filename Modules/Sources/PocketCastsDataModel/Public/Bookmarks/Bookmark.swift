import Foundation
import SwiftUI

/// A bookmark that represents a position in time within an episode
public struct Bookmark: Identifiable {
    public let uuid: String

    public var id: String { uuid }

    public let title: String
    public let time: TimeInterval

    public let created: Date

    public let episodeUuid: String
    public let podcastUuid: String?

    public var episode: BaseEpisode? = nil
    public var podcast: Podcast? = nil

    /// The transcript passage the bookmark captures.
    public var passage: String? = nil

    /// Where `passage` begins in the episode transcript, kept only to disambiguate a
    /// passage that appears more than once — the passage text itself is what's matched.
    public var passageLocation: Int? = nil

    /// The bookmark's position on the transcript's canonical (reference) timeline, when the
    /// episode has a generated transcript and a confident mapping was available when captured.
    ///
    /// Preferred over `time` wherever possible: dynamic ads shift the playback timeline per
    /// device and download, so `time` can point at the wrong content elsewhere, whereas the
    /// reference time is stable. Falls back to `time` when nil.
    public var referenceTime: TimeInterval? = nil

    // For syncing
    public var titleModified: Date? = nil
    public var deletedModified: Date? = nil
    public var passageModified: Date? = nil
    public var referenceTimeModified: Date? = nil
    public var deleted: Bool = false
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
