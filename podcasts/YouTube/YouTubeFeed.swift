import Foundation

/// Represents a YouTube channel/feed that the user has added
public class YouTubeFeed: NSObject, Identifiable, Codable {
    public var id: String // Channel ID
    public var title: String
    public var author: String?
    public var feedDescription: String?
    public var thumbnailURL: String?
    public var feedURL: String // The RSS feed URL
    public var channelURL: String? // The YouTube channel URL
    public var addedDate: Date
    public var lastUpdatedDate: Date?
    public var videoCount: Int

    public init(
        id: String,
        title: String,
        author: String? = nil,
        feedDescription: String? = nil,
        thumbnailURL: String? = nil,
        feedURL: String,
        channelURL: String? = nil,
        addedDate: Date = Date(),
        lastUpdatedDate: Date? = nil,
        videoCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.feedDescription = feedDescription
        self.thumbnailURL = thumbnailURL
        self.feedURL = feedURL
        self.channelURL = channelURL
        self.addedDate = addedDate
        self.lastUpdatedDate = lastUpdatedDate
        self.videoCount = videoCount
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? YouTubeFeed else { return false }
        return other.id == id
    }

    public override var hash: Int {
        id.hashValue
    }

    // MARK: - Preview

    public static func preview() -> YouTubeFeed {
        YouTubeFeed(
            id: "UCxxx123",
            title: "Example YouTube Channel",
            author: "Example Creator",
            feedDescription: "A great YouTube channel about technology",
            thumbnailURL: "https://example.com/thumbnail.jpg",
            feedURL: "https://www.youtube.com/feeds/videos.xml?channel_id=UCxxx123",
            channelURL: "https://www.youtube.com/channel/UCxxx123",
            videoCount: 42
        )
    }
}
