import Foundation

// MARK: - Client Protocol

/// Protocol for authenticated YouTube playlist API calls
protocol YouTubePlaylistAPIClientProtocol: Sendable {
    func fetchMyPlaylists() async throws -> [YouTubeUserPlaylist]
    func fetchPlaylistItems(playlistID: String) async throws -> [YouTubePlaylistVideo]
    func fetchMySubscriptions() async throws -> [YouTubeSubscription]
}

// MARK: - API Errors

enum YouTubePlaylistAPIError: LocalizedError {
    case notAuthenticated
    case badResponse(Int)
    case decodingFailed(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in to YouTube."
        case .badResponse(let code):
            return "YouTube returned an unexpected response (HTTP \(code))."
        case .decodingFailed(let error):
            return "Could not parse the YouTube response: \(error.localizedDescription)"
        case .network(let error):
            return "A network error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - YouTubePlaylistAPIClient

/// Authenticated YouTube Data API v3 client for playlists
actor YouTubePlaylistAPIClient: YouTubePlaylistAPIClientProtocol {

    static let shared = YouTubePlaylistAPIClient()

    private let baseURL = URL(string: "https://www.googleapis.com/youtube/v3")!
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Playlists

    /// Fetches all playlists owned by the authenticated user
    func fetchMyPlaylists() async throws -> [YouTubeUserPlaylist] {
        var allPlaylists: [YouTubeUserPlaylist] = []
        var pageToken: String? = nil

        repeat {
            let page = try await fetchPlaylistPage(pageToken: pageToken)
            allPlaylists.append(contentsOf: page.items.map { $0.toDomain() })
            pageToken = page.nextPageToken
        } while pageToken != nil

        return allPlaylists
    }

    private func fetchPlaylistPage(pageToken: String?) async throws -> YouTubePlaylistListResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("playlists"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "mine", value: "true"),
            URLQueryItem(name: "maxResults", value: "50"),
        ]
        if let token = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw YouTubePlaylistAPIError.notAuthenticated }
        return try await fetch(url: url)
    }

    // MARK: - Playlist Items

    /// Fetches all items in a playlist
    func fetchPlaylistItems(playlistID: String) async throws -> [YouTubePlaylistVideo] {
        var allItems: [YouTubePlaylistVideo] = []
        var pageToken: String? = nil

        repeat {
            let page = try await fetchPlaylistItemPage(playlistID: playlistID, pageToken: pageToken)
            allItems.append(contentsOf: page.items.map { $0.toDomain() })
            pageToken = page.nextPageToken
        } while pageToken != nil

        return allItems
    }

    private func fetchPlaylistItemPage(playlistID: String, pageToken: String?) async throws -> YouTubePlaylistItemListResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("playlistItems"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "playlistId", value: playlistID),
            URLQueryItem(name: "maxResults", value: "50"),
        ]
        if let token = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw YouTubePlaylistAPIError.notAuthenticated }
        return try await fetch(url: url)
    }

    // MARK: - Subscriptions

    /// Fetches all channels the authenticated user is subscribed to
    func fetchMySubscriptions() async throws -> [YouTubeSubscription] {
        var allSubscriptions: [YouTubeSubscription] = []
        var pageToken: String? = nil

        repeat {
            let page = try await fetchSubscriptionPage(pageToken: pageToken)
            allSubscriptions.append(contentsOf: page.items.map { $0.toDomain() })
            pageToken = page.nextPageToken
        } while pageToken != nil

        return allSubscriptions
    }

    private func fetchSubscriptionPage(pageToken: String?) async throws -> YouTubeSubscriptionListResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("subscriptions"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "mine", value: "true"),
            URLQueryItem(name: "maxResults", value: "50"),
            URLQueryItem(name: "order", value: "alphabetical"),
        ]
        if let token = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw YouTubePlaylistAPIError.notAuthenticated }
        return try await fetch(url: url)
    }

    // MARK: - Generic Fetch

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let token = try await YouTubePlaylistAuthManager.shared.validAccessToken()

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw YouTubePlaylistAPIError.network(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw YouTubePlaylistAPIError.badResponse(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw YouTubePlaylistAPIError.decodingFailed(error)
        }
    }
}
