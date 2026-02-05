import Foundation

/// Represents a video from a YouTube feed
public class YouTubeVideo: NSObject, Identifiable, Codable {
    public var id: String // Video ID
    public var feedId: String // Parent feed's channel ID
    public var title: String
    public var videoDescription: String?
    public var thumbnailURL: String?
    public var videoURL: String
    public var publishedDate: Date?
    public var duration: TimeInterval?
    public var viewCount: Int?
    public var author: String?

    /// Computed property for the YouTube watch URL
    public var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(id)")
    }

    /// Computed property for embed URL (useful for in-app playback)
    public var embedURL: URL? {
        URL(string: "https://www.youtube.com/embed/\(id)")
    }

    public init(
        id: String,
        feedId: String,
        title: String,
        videoDescription: String? = nil,
        thumbnailURL: String? = nil,
        videoURL: String,
        publishedDate: Date? = nil,
        duration: TimeInterval? = nil,
        viewCount: Int? = nil,
        author: String? = nil
    ) {
        self.id = id
        self.feedId = feedId
        self.title = title
        self.videoDescription = videoDescription
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.publishedDate = publishedDate
        self.duration = duration
        self.viewCount = viewCount
        self.author = author
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? YouTubeVideo else { return false }
        return other.id == id
    }

    public override var hash: Int {
        id.hashValue
    }

    // MARK: - Preview

    public static func preview() -> YouTubeVideo {
        YouTubeVideo(
            id: "dQw4w9WgXcQ",
            feedId: "UCxxx123",
            title: "Example Video Title",
            videoDescription: "This is an example video description that explains what the video is about.",
            thumbnailURL: "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            videoURL: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            publishedDate: Date(),
            duration: 213,
            viewCount: 1_000_000,
            author: "Example Creator"
        )
    }

    public static func previewList() -> [YouTubeVideo] {
        [
            YouTubeVideo(
                id: "video1",
                feedId: "UCxxx123",
                title: "First Video - Getting Started",
                videoDescription: "Learn the basics in this introductory video",
                thumbnailURL: "https://i.ytimg.com/vi/video1/maxresdefault.jpg",
                videoURL: "https://www.youtube.com/watch?v=video1",
                publishedDate: Date().addingTimeInterval(-86400),
                duration: 600,
                viewCount: 50_000
            ),
            YouTubeVideo(
                id: "video2",
                feedId: "UCxxx123",
                title: "Second Video - Advanced Topics",
                videoDescription: "Dive deeper into advanced concepts",
                thumbnailURL: "https://i.ytimg.com/vi/video2/maxresdefault.jpg",
                videoURL: "https://www.youtube.com/watch?v=video2",
                publishedDate: Date().addingTimeInterval(-172800),
                duration: 1200,
                viewCount: 25_000
            ),
            YouTubeVideo(
                id: "video3",
                feedId: "UCxxx123",
                title: "Third Video - Tips and Tricks",
                videoDescription: "Helpful tips to improve your workflow",
                thumbnailURL: "https://i.ytimg.com/vi/video3/maxresdefault.jpg",
                videoURL: "https://www.youtube.com/watch?v=video3",
                publishedDate: Date().addingTimeInterval(-259200),
                duration: 450,
                viewCount: 75_000
            )
        ]
    }
}
