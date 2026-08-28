import Foundation

/// A podcast network returned by the combined search endpoint.
public struct NetworkSearchResult: Hashable {
    public let uuid: String
    public let title: String
    public let description: String?
    public let collectionImage: String?
    public let podcastCount: Int?

    /// The list of the network's podcasts, which is what opening it shows.
    ///
    /// Search returns no source of its own, so it is built the way the Discover feed spells it:
    /// the network's list, by uuid.
    public var source: String {
        "\(ServerConstants.Urls.lists())\(uuid).json"
    }

    public init(uuid: String, title: String, description: String? = nil, collectionImage: String? = nil, podcastCount: Int? = nil) {
        self.uuid = uuid
        self.title = title
        self.description = description
        self.collectionImage = collectionImage
        self.podcastCount = podcastCount
    }

    public init?(from combinedResult: CombinedSearchResult) {
        guard combinedResult.type == "network" else {
            return nil
        }
        self.uuid = combinedResult.uuid
        self.title = combinedResult.title
        self.description = combinedResult.shortDescription
        self.collectionImage = combinedResult.collectionImage
        self.podcastCount = combinedResult.podcastCount
    }
}
