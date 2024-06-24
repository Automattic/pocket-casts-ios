import Foundation
import PocketCastsDataModel

struct PodcastsSearchEnvelope: Decodable {
    let status: String
    let message: String?
    let result: PodcastsSearchEnvelopeResult
}

struct PodcastsSearchEnvelopeResult: Decodable {
    /// Podcast returned when the user searches directly for a URL
    let podcast: PodcastFolderSearchResult?

    /// Regular search results based on a search term
    let searchResults: [PodcastFolderSearchResult]?

    /// The poll uuid if the result is still being processed on the server
    let pollUuid: String?
}

public struct PodcastFolderSearchResult: Codable, Hashable {
    public let uuid: String
    public let title: String?
    public let author: String?
    public let kind: Kind
    public var isLocal: Bool?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.title = try? container.decode(String.self, forKey: .title)
        self.author = try? container.decode(String.self, forKey: .author)
        self.kind = (try? container.decodeIfPresent(Kind.self, forKey: .kind)) ?? .podcast
        self.isLocal = (try? container.decode(Bool.self, forKey: .isLocal)) ?? false
    }

    public init?(from podcast: Podcast) {
        self.uuid = podcast.uuid
        self.title = podcast.title
        self.author = podcast.author
        self.isLocal = true
        self.kind = .podcast
    }

    public init?(from folder: Folder) {
        self.uuid = folder.uuid
        self.title = folder.name
        self.author = ""
        self.isLocal = true
        self.kind = .folder
    }

    public enum Kind: Codable {
        case podcast, folder
    }

    static public func ==(lhs: PodcastFolderSearchResult, rhs: PodcastFolderSearchResult) -> Bool {
        lhs.kind == rhs.kind && lhs.uuid == rhs.uuid
    }
}

extension PodcastFolderSearchResult: Identifiable {
    public var id: String {
        uuid
    }
}

public class PodcastSearchTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(term: String) async throws -> [PodcastFolderSearchResult] {
        var envelope: PodcastsSearchEnvelope?
        var retry = true
        var pollCount = 0
        while retry {
            envelope = try await search(term: term)
            // Check if status of search is poll, if it's polled we will repeat the call after x amount of secs.
            pollCount += 1
            let backOffTime = pollBackoffTime(pollCount: pollCount)
            guard envelope?.status == "poll", backOffTime > 0 else {
                retry = false
                continue
            }

            try await Task.sleep(nanoseconds: backOffTime)
        }

        if let podcast = envelope?.result.podcast {
            return [podcast]
        } else {
            return envelope?.result.searchResults ?? []
        }
    }

    private func search(term: String) async throws -> PodcastsSearchEnvelope {
        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "podcasts/search")
        let request = ServerHelper.createJsonRequest(url: url, params: MainServerHandler.shared.podcastSearchQuery(searchTerm: term)!, timeout: 10, cachePolicy: .reloadIgnoringCacheData)

        let (data, _) = try await session.data(for: request!)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(PodcastsSearchEnvelope.self, from: data)
        return envelope
    }

    private func pollBackoffTime(pollCount: Int) -> UInt64 {
        let multiply = pow(10, 9)

        return UInt64(NSDecimalNumber(decimal: Decimal(pollCount.pollWaitingTime) * multiply).uint64Value)
    }
}

extension Int {
    // Return a correspondent poll waiting time for a given number
    // From 1 to 2: 2 seconds
    // From 3 to 6: 5 second
    // For 7: 10 seconds
    // Others: -1
    var pollWaitingTime: TimeInterval {
        switch self {
        case 1..<3:
            2
        case 3..<7:
            5
        case 7:
            10
        default:
            -1
        }
    }
}
