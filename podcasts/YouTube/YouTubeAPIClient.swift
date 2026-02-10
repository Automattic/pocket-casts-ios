import Foundation
import PocketCastsUtils

/// Configuration for the YouTube Data API
public struct YouTubeAPIConfig {
    /// The YouTube Data API v3 key
    /// Get one at: https://console.cloud.google.com/apis/credentials
    public static var apiKey: String {
        // Try to load from a plist or environment
        // For production, this should be stored securely (e.g., in Keychain or server-side)
        if let path = Bundle.main.path(forResource: "YouTubeAPI", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["API_KEY"] as? String, !key.isEmpty {
            return key
        }

        // Fallback: Check for environment variable (useful for development)
        if let key = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"], !key.isEmpty {
            return key
        }

        // Return empty - API calls will fail gracefully
        return ""
    }

    /// Check if API is configured
    public static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}

/// Error types for YouTube API operations
public enum YouTubeAPIError: Error, LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case networkError(Error)
    case apiError(code: Int, message: String)
    case decodingError(Error)
    case channelNotFound
    case quotaExceeded
    case rateLimited

    public var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "YouTube API key is not configured. Please add your API key."
        case .invalidURL:
            return "Invalid YouTube URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "YouTube API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .channelNotFound:
            return "YouTube channel not found"
        case .quotaExceeded:
            return "YouTube API quota exceeded. Please try again later."
        case .rateLimited:
            return "Too many requests. Please try again later."
        }
    }
}

/// Client for the YouTube Data API v3
public class YouTubeAPIClient {
    public static let shared = YouTubeAPIClient()

    private let baseURL = "https://www.googleapis.com/youtube/v3"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Channel Operations

    /// Get channel info by channel ID
    public func getChannel(byId channelId: String) async throws -> YouTubeChannelResponse.Item {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeAPIError.apiKeyNotConfigured
        }

        var components = URLComponents(string: "\(baseURL)/channels")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "id", value: channelId),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey)
        ]

        let response: YouTubeChannelResponse = try await request(url: components.url!)

        guard let channel = response.items.first else {
            throw YouTubeAPIError.channelNotFound
        }

        return channel
    }

    /// Get channel info by username
    public func getChannel(byUsername username: String) async throws -> YouTubeChannelResponse.Item {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeAPIError.apiKeyNotConfigured
        }

        var components = URLComponents(string: "\(baseURL)/channels")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "forUsername", value: username),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey)
        ]

        let response: YouTubeChannelResponse = try await request(url: components.url!)

        guard let channel = response.items.first else {
            throw YouTubeAPIError.channelNotFound
        }

        return channel
    }

    /// Search for a channel by handle (custom URL)
    public func searchChannel(byHandle handle: String) async throws -> YouTubeChannelResponse.Item {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeAPIError.apiKeyNotConfigured
        }

        // First, search for the channel
        var searchComponents = URLComponents(string: "\(baseURL)/search")!
        searchComponents.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: handle),
            URLQueryItem(name: "type", value: "channel"),
            URLQueryItem(name: "maxResults", value: "5"),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey)
        ]

        let searchResponse: YouTubeSearchResponse = try await request(url: searchComponents.url!)

        // Find the channel that matches the handle
        guard let channelResult = searchResponse.items.first(where: { item in
            // Check if the custom URL or title matches
            item.snippet.channelTitle.lowercased().replacingOccurrences(of: " ", with: "") == handle.lowercased()
        }) ?? searchResponse.items.first else {
            throw YouTubeAPIError.channelNotFound
        }

        // Get full channel details
        return try await getChannel(byId: channelResult.snippet.channelId)
    }

    // MARK: - Video Operations

    /// Get videos from a channel's uploads playlist
    public func getChannelVideos(channelId: String, maxResults: Int = 50) async throws -> [YouTubeVideoItem] {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeAPIError.apiKeyNotConfigured
        }

        // First, get the channel to find the uploads playlist ID
        let channel = try await getChannel(byId: channelId)

        guard let uploadsPlaylistId = channel.contentDetails?.relatedPlaylists.uploads else {
            return []
        }

        // Get playlist items
        var components = URLComponents(string: "\(baseURL)/playlistItems")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "playlistId", value: uploadsPlaylistId),
            URLQueryItem(name: "maxResults", value: String(min(maxResults, 50))),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey)
        ]

        let playlistResponse: YouTubePlaylistItemsResponse = try await request(url: components.url!)

        // Get video IDs for additional details
        let videoIds = playlistResponse.items.compactMap { $0.contentDetails?.videoId }

        if videoIds.isEmpty {
            return []
        }

        // Get full video details (duration, view count, etc.)
        return try await getVideoDetails(videoIds: videoIds)
    }

    /// Get detailed video information
    public func getVideoDetails(videoIds: [String]) async throws -> [YouTubeVideoItem] {
        guard YouTubeAPIConfig.isConfigured else {
            throw YouTubeAPIError.apiKeyNotConfigured
        }

        var components = URLComponents(string: "\(baseURL)/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "id", value: videoIds.joined(separator: ",")),
            URLQueryItem(name: "key", value: YouTubeAPIConfig.apiKey)
        ]

        let response: YouTubeVideosResponse = try await request(url: components.url!)
        return response.items
    }

    // MARK: - Private Methods

    private func request<T: Decodable>(url: URL) async throws -> T {
        FileLog.shared.addMessage("YouTubeAPIClient: Requesting \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw YouTubeAPIError.networkError(NSError(domain: "YouTubeAPI", code: -1))
            }

            // Check for API errors
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(YouTubeErrorResponse.self, from: data) {
                    let error = errorResponse.error

                    // Handle specific error codes
                    if error.code == 403 && error.errors.contains(where: { $0.reason == "quotaExceeded" }) {
                        throw YouTubeAPIError.quotaExceeded
                    }
                    if error.code == 429 {
                        throw YouTubeAPIError.rateLimited
                    }

                    throw YouTubeAPIError.apiError(code: error.code, message: error.message)
                }

                throw YouTubeAPIError.apiError(code: httpResponse.statusCode, message: "Unknown error")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode(T.self, from: data)
        } catch let error as YouTubeAPIError {
            throw error
        } catch let error as DecodingError {
            FileLog.shared.addMessage("YouTubeAPIClient: Decoding error - \(error)")
            throw YouTubeAPIError.decodingError(error)
        } catch {
            FileLog.shared.addMessage("YouTubeAPIClient: Network error - \(error)")
            throw YouTubeAPIError.networkError(error)
        }
    }
}

// MARK: - API Response Models

public struct YouTubeErrorResponse: Decodable {
    public let error: ErrorDetail

    public struct ErrorDetail: Decodable {
        public let code: Int
        public let message: String
        public let errors: [ErrorItem]
    }

    public struct ErrorItem: Decodable {
        public let reason: String
        public let message: String
    }
}

public struct YouTubeChannelResponse: Decodable {
    public let items: [Item]

    public struct Item: Decodable {
        public let id: String
        public let snippet: Snippet
        public let contentDetails: ContentDetails?
        public let statistics: Statistics?
    }

    public struct Snippet: Decodable {
        public let title: String
        public let description: String
        public let customUrl: String?
        public let thumbnails: Thumbnails
    }

    public struct Thumbnails: Decodable {
        public let `default`: Thumbnail?
        public let medium: Thumbnail?
        public let high: Thumbnail?
    }

    public struct Thumbnail: Decodable {
        public let url: String
    }

    public struct ContentDetails: Decodable {
        public let relatedPlaylists: RelatedPlaylists
    }

    public struct RelatedPlaylists: Decodable {
        public let uploads: String
    }

    public struct Statistics: Decodable {
        public let subscriberCount: String?
        public let videoCount: String?
    }
}

public struct YouTubeSearchResponse: Decodable {
    public let items: [Item]

    public struct Item: Decodable {
        public let snippet: Snippet
    }

    public struct Snippet: Decodable {
        public let channelId: String
        public let channelTitle: String
    }
}

public struct YouTubePlaylistItemsResponse: Decodable {
    public let items: [Item]

    public struct Item: Decodable {
        public let snippet: Snippet
        public let contentDetails: ContentDetails?
    }

    public struct Snippet: Decodable {
        public let title: String
        public let description: String
        public let thumbnails: YouTubeChannelResponse.Thumbnails
        public let channelTitle: String
        public let publishedAt: Date?
    }

    public struct ContentDetails: Decodable {
        public let videoId: String
    }
}

public struct YouTubeVideosResponse: Decodable {
    public let items: [YouTubeVideoItem]
}

public struct YouTubeVideoItem: Decodable {
    public let id: String
    public let snippet: Snippet
    public let contentDetails: ContentDetails?
    public let statistics: Statistics?

    public struct Snippet: Decodable {
        public let title: String
        public let description: String
        public let thumbnails: YouTubeChannelResponse.Thumbnails
        public let channelTitle: String
        public let channelId: String
        public let publishedAt: Date?
    }

    public struct ContentDetails: Decodable {
        public let duration: String // ISO 8601 duration format (e.g., "PT4M13S")
    }

    public struct Statistics: Decodable {
        public let viewCount: String?
        public let likeCount: String?
    }
}

// MARK: - Duration Parsing

extension YouTubeVideoItem.ContentDetails {
    /// Parse ISO 8601 duration to seconds
    public var durationInSeconds: TimeInterval? {
        parseDuration(duration)
    }

    private func parseDuration(_ duration: String) -> TimeInterval? {
        // Format: PT#H#M#S or PT#M#S or PT#S
        guard duration.hasPrefix("PT") else { return nil }

        let durationString = String(duration.dropFirst(2))
        var totalSeconds: TimeInterval = 0

        var currentNumber = ""
        for char in durationString {
            if char.isNumber {
                currentNumber += String(char)
            } else if let number = Double(currentNumber) {
                switch char {
                case "H":
                    totalSeconds += number * 3600
                case "M":
                    totalSeconds += number * 60
                case "S":
                    totalSeconds += number
                default:
                    break
                }
                currentNumber = ""
            }
        }

        return totalSeconds
    }
}
