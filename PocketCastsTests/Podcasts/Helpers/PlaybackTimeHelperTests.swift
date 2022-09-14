import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class PlaybackTimeHelperTests: XCTestCase {
    func testLastSevenDaysPlaytimeWhenNothingIsReturned() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)
        dataManagerMock.episodesToReturn = []

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInSeconds()

        XCTAssertEqual(playbackTime, 0)
    }
}

class DataManagerMock: DataManager {
    var episodesToReturn: [Episode] = []

    override func findEpisodesWhere(customWhere: String, arguments: [Any]?) -> [Episode] {
        return []
    }
}
