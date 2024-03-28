import Foundation

@testable import PocketCastsDataModel

class DataManagerMock: DataManager {
    var podcastsToReturn: [Podcast] = []
    var episodesToReturn: [Episode] = []

    override func findEpisodesWhere(customWhere: String, arguments: [Any]?) -> [Episode] {
        return episodesToReturn
    }

    override func allPodcasts(includeUnsubscribed: Bool, reloadFromDatabase: Bool = false) -> [Podcast] {
        return podcastsToReturn
    }
}
