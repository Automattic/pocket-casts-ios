import Foundation

@testable import PocketCastsDataModel

class DataManagerMock: DataManager {
    var episodesToReturn: [Episode] = []

    override func findEpisodesWhere(customWhere: String, arguments: [Any]?) -> [Episode] {
        return episodesToReturn
    }
}
