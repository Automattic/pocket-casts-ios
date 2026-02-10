import Foundation
import PocketCastsUtils

/// Error types for YouTube feed parsing
public enum YouTubeFeedParserError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case channelNotFound
    case unsupportedURLType
    case apiNotConfigured
    case apiError(YouTubeAPIError)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid YouTube URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Failed to parse feed: \(message)"
        case .channelNotFound:
            return "YouTube channel not found"
        case .unsupportedURLType:
            return "This type of YouTube URL is not supported. Please use a channel URL."
        case .apiNotConfigured:
            return "YouTube API is not configured. Please add your API key to use this feature."
        case .apiError(let error):
            return error.localizedDescription
        }
    }
}

/// Fetches YouTube channel and video data using the official YouTube Data API v3
public class YouTubeFeedParser {
    public static let shared = YouTubeFeedParser()

    private let apiClient = YouTubeAPIClient.shared

    private init() {}

    // MARK: - Public Methods

    /// Check if the YouTube API is configured
    public var isAPIConfigured: Bool {
        YouTubeAPIConfig.isConfigured
    }

    /// Fetch and parse a YouTube feed from a URL
    public func fetchFeed(from urlString: String) async throws -> (feed: YouTubeFeed, videos: [YouTubeVideo]) {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeFeedParserError.apiNotConfigured
        }

        let urlType = YouTubeURLDetector.parseURL(urlString)

        switch urlType {
        case .channel(let channelId):
            return try await fetchChannelFeed(channelId: channelId)

        case .user(let username):
            return try await fetchChannelFeedByUsername(username: username)

        case .handle(let handle):
            return try await fetchChannelFeedByHandle(handle: handle)

        case .rssFeed:
            // Try to extract channel ID from RSS URL
            if let channelId = extractChannelIdFromRSSURL(urlString) {
                return try await fetchChannelFeed(channelId: channelId)
            }
            throw YouTubeFeedParserError.unsupportedURLType

        case .video, .playlist, .unknown:
            throw YouTubeFeedParserError.unsupportedURLType
        }
    }

    /// Refresh videos for an existing feed
    public func refreshFeed(_ feed: YouTubeFeed) async throws -> [YouTubeVideo] {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeFeedParserError.apiNotConfigured
        }

        do {
            let videoItems = try await apiClient.getChannelVideos(channelId: feed.id, maxResults: 50)
            return videoItems.map { convertToYouTubeVideo($0, feedId: feed.id) }
        } catch let error as YouTubeAPIError {
            throw YouTubeFeedParserError.apiError(error)
        }
    }

    // MARK: - Private Methods

    private func fetchChannelFeed(channelId: String) async throws -> (feed: YouTubeFeed, videos: [YouTubeVideo]) {
        do {
            let channel = try await apiClient.getChannel(byId: channelId)
            let videoItems = try await apiClient.getChannelVideos(channelId: channelId, maxResults: 50)

            let feed = convertToYouTubeFeed(channel)
            let videos = videoItems.map { convertToYouTubeVideo($0, feedId: channelId) }

            return (feed, videos)
        } catch let error as YouTubeAPIError {
            if case .channelNotFound = error {
                throw YouTubeFeedParserError.channelNotFound
            }
            throw YouTubeFeedParserError.apiError(error)
        }
    }

    private func fetchChannelFeedByUsername(username: String) async throws -> (feed: YouTubeFeed, videos: [YouTubeVideo]) {
        do {
            let channel = try await apiClient.getChannel(byUsername: username)
            let videoItems = try await apiClient.getChannelVideos(channelId: channel.id, maxResults: 50)

            let feed = convertToYouTubeFeed(channel)
            let videos = videoItems.map { convertToYouTubeVideo($0, feedId: channel.id) }

            return (feed, videos)
        } catch let error as YouTubeAPIError {
            if case .channelNotFound = error {
                throw YouTubeFeedParserError.channelNotFound
            }
            throw YouTubeFeedParserError.apiError(error)
        }
    }

    private func fetchChannelFeedByHandle(handle: String) async throws -> (feed: YouTubeFeed, videos: [YouTubeVideo]) {
        do {
            let channel = try await apiClient.searchChannel(byHandle: handle)
            let videoItems = try await apiClient.getChannelVideos(channelId: channel.id, maxResults: 50)

            let feed = convertToYouTubeFeed(channel)
            let videos = videoItems.map { convertToYouTubeVideo($0, feedId: channel.id) }

            return (feed, videos)
        } catch let error as YouTubeAPIError {
            if case .channelNotFound = error {
                throw YouTubeFeedParserError.channelNotFound
            }
            throw YouTubeFeedParserError.apiError(error)
        }
    }

    private func extractChannelIdFromRSSURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        return queryItems.first(where: { $0.name == "channel_id" })?.value
    }

    // MARK: - Conversion Methods

    private func convertToYouTubeFeed(_ channel: YouTubeChannelResponse.Item) -> YouTubeFeed {
        let thumbnailURL = channel.snippet.thumbnails.high?.url
            ?? channel.snippet.thumbnails.medium?.url
            ?? channel.snippet.thumbnails.default?.url

        let videoCount = Int(channel.statistics?.videoCount ?? "0") ?? 0

        return YouTubeFeed(
            id: channel.id,
            title: channel.snippet.title,
            author: channel.snippet.title,
            feedDescription: channel.snippet.description.isEmpty ? nil : channel.snippet.description,
            thumbnailURL: thumbnailURL,
            feedURL: "https://www.youtube.com/channel/\(channel.id)",
            channelURL: "https://www.youtube.com/channel/\(channel.id)",
            addedDate: Date(),
            lastUpdatedDate: Date(),
            videoCount: videoCount
        )
    }

    private func convertToYouTubeVideo(_ item: YouTubeVideoItem, feedId: String) -> YouTubeVideo {
        let thumbnailURL = item.snippet.thumbnails.high?.url
            ?? item.snippet.thumbnails.medium?.url
            ?? item.snippet.thumbnails.default?.url

        let viewCount = item.statistics?.viewCount.flatMap { Int($0) }
        let duration = item.contentDetails?.durationInSeconds

        return YouTubeVideo(
            id: item.id,
            feedId: feedId,
            title: item.snippet.title,
            videoDescription: item.snippet.description.isEmpty ? nil : item.snippet.description,
            thumbnailURL: thumbnailURL,
            videoURL: "https://www.youtube.com/watch?v=\(item.id)",
            publishedDate: item.snippet.publishedAt,
            duration: duration,
            viewCount: viewCount,
            author: item.snippet.channelTitle
        )
    }
}
