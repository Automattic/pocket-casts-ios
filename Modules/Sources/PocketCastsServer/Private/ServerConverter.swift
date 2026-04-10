import Foundation

// our server has different enum values for some types, we convert them in this class
class ServerConverter {
    class func convertToServerSortType(clientType: Int) -> Int32 {
        let clientSort = PodcastLibrarySortClient(rawValue: clientType) ?? .dateAddedNewestToOldest

        switch clientSort {
        case .dateAddedNewestToOldest:
            return PodcastLibrarySortServer.dateAddedNewestToOldest.rawValue
        case .titleAtoZ:
            return PodcastLibrarySortServer.titleAtoZ.rawValue
        case .episodeDateNewestToOldest:
            return PodcastLibrarySortServer.episodeDateNewestToOldest.rawValue
        case .custom:
            return PodcastLibrarySortServer.custom.rawValue
        case .recentlyPlayed:
            return PodcastLibrarySortServer.recentlyPlayed.rawValue
        }
    }

    class func convertToClientSortType(serverType: Int32) -> Int {
        let serverSort = PodcastLibrarySortServer(rawValue: serverType) ?? .dateAddedNewestToOldest
        switch serverSort {
        case .dateAddedNewestToOldest:
            return PodcastLibrarySortClient.dateAddedNewestToOldest.rawValue
        case .titleAtoZ:
            return PodcastLibrarySortClient.titleAtoZ.rawValue
        case .episodeDateNewestToOldest:
            return PodcastLibrarySortClient.episodeDateNewestToOldest.rawValue
        case .custom:
            return PodcastLibrarySortClient.custom.rawValue
        case .recentlyPlayed:
            return PodcastLibrarySortClient.recentlyPlayed.rawValue
        }
    }
}

enum PodcastLibrarySortClient: Int {
    case dateAddedNewestToOldest = 1, titleAtoZ = 2, episodeDateNewestToOldest = 5, custom = 6, recentlyPlayed = 7
}

enum PodcastLibrarySortServer: Int32 {
    case dateAddedNewestToOldest = 0, titleAtoZ = 1, episodeDateNewestToOldest = 2, custom = 3, recentlyPlayed = 4
}
