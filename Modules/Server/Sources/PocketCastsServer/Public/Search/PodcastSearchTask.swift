import Foundation
import PocketCastsDataModel

public struct PodcastFolderSearchResult: Codable, Hashable {
    public let uuid: String
    public let title: String
    public let author: String
    public let kind: Kind

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.kind = .podcast
    }

    public init?(from podcast: Podcast) {
        if let title = podcast.title, let author = podcast.author {
            self.uuid = podcast.uuid
            self.title = title
            self.author = author
            self.kind = .podcast
        } else {
            return nil
        }
    }

    public init?(from folder: Folder) {
        self.uuid = folder.uuid
        self.title = folder.name
        self.author = ""
        self.kind = .folder
    }

    public enum Kind: Codable {
        case podcast, folder
    }
}

public class PodcastSearchTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }
    public func search(term: String) async throws -> [PodcastFolderSearchResult] {
        let searchURL = URL(string: "\(ServerConstants.Urls.cache())discover/search")!
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"

        let json: [String: Any] = ["term": term]

        let jsonData = try JSONSerialization.data(withJSONObject: json)

        request.httpBody = jsonData

        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode([PodcastFolderSearchResult].self, from: data)
    }
}
