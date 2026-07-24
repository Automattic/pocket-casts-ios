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

    // For syncing
    public var titleModified: Date? = nil
    public var deletedModified: Date? = nil
    public var deleted: Bool = false

    // `BaseEpisode` and `Podcast` don't conform to Hashable, so instead we implement it manually to ignore those properties
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(title)
        hasher.combine(time)
        hasher.combine(created)
        hasher.combine(episodeUuid)
        hasher.combine(podcastUuid)
        hasher.combine(titleModified)
        hasher.combine(deletedModified)
    }

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

// MARK: - Identifiable

extension Bookmark: Identifiable {
    public var id: String { uuid }
}

// MARK: - Passage

extension Bookmark {
    /// The transcript passage the bookmark captures.
    ///
    /// Temporarily backed by `UserDefaults`, until the passage is stored with the bookmark itself.
    public var passage: String? {
        get { UserDefaults.standard.string(forKey: Self.passageKey(for: uuid)) }
        nonmutating set {
            let key = Self.passageKey(for: uuid)
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// Where `passage` begins in the episode transcript, kept only to disambiguate a
    /// passage that appears more than once — the passage text itself is what's matched.
    ///
    /// Temporarily backed by `UserDefaults`, until it's stored with the bookmark itself.
    public var passageLocation: Int? {
        get { UserDefaults.standard.object(forKey: Self.passageLocationKey(for: uuid)) as? Int }
        nonmutating set {
            let key = Self.passageLocationKey(for: uuid)
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    private static func passageKey(for uuid: String) -> String {
        "bookmark.passage.\(uuid)"
    }

    private static func passageLocationKey(for uuid: String) -> String {
        "bookmark.passageLocation.\(uuid)"
    }
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
