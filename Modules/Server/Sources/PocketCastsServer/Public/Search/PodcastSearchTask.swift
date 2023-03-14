import Foundation
import PocketCastsDataModel

public struct PodcastFolderSearchResult: Codable, Hashable {
    public let uuid: String
    public let title: String
    public let author: String
    public let isFolder: Bool?
    public var isLocal: Bool?

    public init?(from podcast: Podcast) {
        if let title = podcast.title, let author = podcast.author {
            self.uuid = podcast.uuid
            self.title = title
            self.author = author
            self.isLocal = true
            self.isFolder = nil
        } else {
            return nil
        }
    }

    public init?(from folder: Folder) {
        self.uuid = folder.uuid
        self.title = folder.name
        self.author = ""
        self.isFolder = true
        self.isLocal = true
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
