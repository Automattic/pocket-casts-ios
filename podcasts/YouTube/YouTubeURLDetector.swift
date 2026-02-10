import Foundation

/// Utility for detecting and parsing YouTube URLs
public struct YouTubeURLDetector {

    /// Types of YouTube URLs we can handle
    public enum YouTubeURLType {
        case channel(id: String)
        case user(username: String)
        case handle(handle: String) // @username format
        case rssFeed(url: String)
        case video(id: String)
        case playlist(id: String)
        case unknown
    }

    /// Check if a string is a YouTube URL
    public static func isYouTubeURL(_ urlString: String) -> Bool {
        let lowercased = urlString.lowercased()
        return lowercased.contains("youtube.com") || lowercased.contains("youtu.be")
    }

    /// Parse a YouTube URL and determine its type
    public static func parseURL(_ urlString: String) -> YouTubeURLType {
        guard let url = URL(string: urlString) else { return .unknown }

        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        // Check if it's a YouTube domain
        guard host.contains("youtube.com") || host.contains("youtu.be") else {
            return .unknown
        }

        // RSS Feed URL
        if path.contains("/feeds/videos.xml") {
            if let channelId = url.queryValue(for: "channel_id") {
                return .rssFeed(url: urlString)
            }
            if let userId = url.queryValue(for: "user") {
                return .rssFeed(url: urlString)
            }
            if let playlistId = url.queryValue(for: "playlist_id") {
                return .rssFeed(url: urlString)
            }
        }

        // Channel URL: youtube.com/channel/CHANNEL_ID
        if path.starts(with: "/channel/") {
            let channelId = String(url.path.dropFirst("/channel/".count)).components(separatedBy: "/").first ?? ""
            if !channelId.isEmpty {
                return .channel(id: channelId)
            }
        }

        // User URL: youtube.com/user/USERNAME
        if path.starts(with: "/user/") {
            let username = String(url.path.dropFirst("/user/".count)).components(separatedBy: "/").first ?? ""
            if !username.isEmpty {
                return .user(username: username)
            }
        }

        // Handle URL: youtube.com/@username
        if path.starts(with: "/@") {
            var handle = String(url.path.dropFirst("/@".count)).components(separatedBy: "/").first ?? ""
            // Remove trailing punctuation that might be accidentally included (e.g., periods, commas)
            while let last = handle.last, !last.isLetter && !last.isNumber && last != "_" && last != "-" {
                handle.removeLast()
            }
            if !handle.isEmpty {
                return .handle(handle: handle)
            }
        }

        // Video URL: youtube.com/watch?v=VIDEO_ID or youtu.be/VIDEO_ID
        if let videoId = url.queryValue(for: "v") {
            return .video(id: videoId)
        }
        if host.contains("youtu.be") {
            let videoId = String(url.path.dropFirst())
            if !videoId.isEmpty {
                return .video(id: videoId)
            }
        }

        // Playlist URL
        if let playlistId = url.queryValue(for: "list") {
            return .playlist(id: playlistId)
        }

        // Check if path might be a custom channel URL (youtube.com/c/ChannelName or just youtube.com/ChannelName)
        if path.starts(with: "/c/") {
            let channelName = String(url.path.dropFirst("/c/".count)).components(separatedBy: "/").first ?? ""
            if !channelName.isEmpty {
                return .handle(handle: channelName)
            }
        }

        return .unknown
    }

    /// Convert a YouTube URL to an RSS feed URL
    public static func toRSSFeedURL(_ urlString: String) -> String? {
        let urlType = parseURL(urlString)

        switch urlType {
        case .rssFeed(let url):
            return url
        case .channel(let id):
            return "https://www.youtube.com/feeds/videos.xml?channel_id=\(id)"
        case .user(let username):
            return "https://www.youtube.com/feeds/videos.xml?user=\(username)"
        case .handle(let handle):
            // Handle URLs require resolving the channel ID first
            // Return nil for now - we'll need to resolve this via web scraping or API
            return nil
        case .video, .playlist, .unknown:
            return nil
        }
    }

    /// Check if the URL type is something we can add as a feed
    public static func canAddAsFeed(_ urlType: YouTubeURLType) -> Bool {
        switch urlType {
        case .channel, .user, .handle, .rssFeed:
            return true
        case .video, .playlist, .unknown:
            return false
        }
    }
}

// MARK: - URL Extension

private extension URL {
    func queryValue(for key: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.first(where: { $0.name == key })?.value
    }
}
