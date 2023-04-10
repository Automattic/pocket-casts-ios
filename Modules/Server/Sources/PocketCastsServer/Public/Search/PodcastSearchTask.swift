import Foundation
import PocketCastsDataModel

struct PodcastsSearchEnvelope: Decodable {
    let result: PodcastsSearchEnvelopeResult
}

struct PodcastsSearchEnvelopeResult: Decodable {
    /// Podcast returned when the user searches directly for a URL
    let podcast: PodcastFolderSearchResult?

    /// Regular search results based on a search term
    let searchResults: [PodcastFolderSearchResult]
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
        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "podcasts/search")
        let request = ServerHelper.createJsonRequest(url: url, params: MainServerHandler.shared.podcastSearchQuery(searchTerm: term)!, timeout: 10, cachePolicy: .reloadIgnoringCacheData)

        let (data, _) = try await session.data(for: request!)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let envelope = try decoder.decode(PodcastsSearchEnvelope.self, from: data)
        if let podcast = envelope.result.podcast {
            return [podcast]
        } else {
            return envelope.result.searchResults
        }
    }
}
