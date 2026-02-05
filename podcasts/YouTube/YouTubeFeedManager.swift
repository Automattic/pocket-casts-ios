import Foundation
import PocketCastsUtils

/// Manages storage and retrieval of YouTube feeds
public class YouTubeFeedManager {
    public static let shared = YouTubeFeedManager()

    private let feedsKey = "YouTubeFeeds"
    private let videosKey = "YouTubeVideos"

    private var cachedFeeds: [YouTubeFeed]?
    private var cachedVideos: [String: [YouTubeVideo]]? // keyed by feedId

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - File Paths

    private var feedsFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("youtube_feeds.json")
    }

    private var videosFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("youtube_videos.json")
    }

    // MARK: - Feed Management

    /// Get all saved YouTube feeds
    public func allFeeds() -> [YouTubeFeed] {
        if let cached = cachedFeeds {
            return cached
        }

        guard let data = try? Data(contentsOf: feedsFileURL),
              let feeds = try? JSONDecoder().decode([YouTubeFeed].self, from: data) else {
            return []
        }

        cachedFeeds = feeds
        return feeds
    }

    /// Get a specific feed by ID
    public func feed(withId id: String) -> YouTubeFeed? {
        allFeeds().first { $0.id == id }
    }

    /// Add a new YouTube feed
    public func addFeed(_ feed: YouTubeFeed) {
        var feeds = allFeeds()

        // Check if feed already exists
        if let existingIndex = feeds.firstIndex(where: { $0.id == feed.id }) {
            feeds[existingIndex] = feed
        } else {
            feeds.append(feed)
        }

        saveFeeds(feeds)

        NotificationCenter.default.post(name: .youTubeFeedAdded, object: feed)
        FileLog.shared.addMessage("YouTubeFeedManager: Added feed '\(feed.title)' with ID \(feed.id)")
    }

    /// Remove a YouTube feed
    public func removeFeed(_ feed: YouTubeFeed) {
        removeFeed(withId: feed.id)
    }

    /// Remove a YouTube feed by ID
    public func removeFeed(withId id: String) {
        var feeds = allFeeds()
        feeds.removeAll { $0.id == id }
        saveFeeds(feeds)

        // Also remove associated videos
        removeVideos(forFeedId: id)

        NotificationCenter.default.post(name: .youTubeFeedRemoved, object: id)
        FileLog.shared.addMessage("YouTubeFeedManager: Removed feed with ID \(id)")
    }

    /// Check if a feed exists
    public func feedExists(withId id: String) -> Bool {
        allFeeds().contains { $0.id == id }
    }

    /// Update an existing feed
    public func updateFeed(_ feed: YouTubeFeed) {
        var feeds = allFeeds()
        if let index = feeds.firstIndex(where: { $0.id == feed.id }) {
            feeds[index] = feed
            saveFeeds(feeds)
            NotificationCenter.default.post(name: .youTubeFeedUpdated, object: feed)
        }
    }

    private func saveFeeds(_ feeds: [YouTubeFeed]) {
        cachedFeeds = feeds

        do {
            let data = try JSONEncoder().encode(feeds)
            try data.write(to: feedsFileURL)
        } catch {
            FileLog.shared.addMessage("YouTubeFeedManager: Error saving feeds - \(error)")
        }
    }

    // MARK: - Video Management

    /// Get all videos for a specific feed
    public func videos(forFeedId feedId: String) -> [YouTubeVideo] {
        let allVideos = loadAllVideos()
        return allVideos[feedId] ?? []
    }

    /// Save videos for a feed
    public func saveVideos(_ videos: [YouTubeVideo], forFeedId feedId: String) {
        var allVideos = loadAllVideos()
        allVideos[feedId] = videos
        saveAllVideos(allVideos)

        // Update feed's video count
        if var feed = feed(withId: feedId) {
            feed.videoCount = videos.count
            feed.lastUpdatedDate = Date()
            updateFeed(feed)
        }
    }

    /// Remove all videos for a feed
    public func removeVideos(forFeedId feedId: String) {
        var allVideos = loadAllVideos()
        allVideos.removeValue(forKey: feedId)
        saveAllVideos(allVideos)
    }

    private func loadAllVideos() -> [String: [YouTubeVideo]] {
        if let cached = cachedVideos {
            return cached
        }

        guard let data = try? Data(contentsOf: videosFileURL),
              let videos = try? JSONDecoder().decode([String: [YouTubeVideo]].self, from: data) else {
            return [:]
        }

        cachedVideos = videos
        return videos
    }

    private func saveAllVideos(_ videos: [String: [YouTubeVideo]]) {
        cachedVideos = videos

        do {
            let data = try JSONEncoder().encode(videos)
            try data.write(to: videosFileURL)
        } catch {
            FileLog.shared.addMessage("YouTubeFeedManager: Error saving videos - \(error)")
        }
    }

    // MARK: - Utilities

    /// Clear all YouTube data
    public func clearAllData() {
        cachedFeeds = nil
        cachedVideos = nil

        try? fileManager.removeItem(at: feedsFileURL)
        try? fileManager.removeItem(at: videosFileURL)

        NotificationCenter.default.post(name: .youTubeFeedsCleared, object: nil)
        FileLog.shared.addMessage("YouTubeFeedManager: Cleared all data")
    }

    /// Get total number of feeds
    public var feedCount: Int {
        allFeeds().count
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let youTubeFeedAdded = Notification.Name("YouTubeFeedAdded")
    static let youTubeFeedRemoved = Notification.Name("YouTubeFeedRemoved")
    static let youTubeFeedUpdated = Notification.Name("YouTubeFeedUpdated")
    static let youTubeFeedsCleared = Notification.Name("YouTubeFeedsCleared")
}
