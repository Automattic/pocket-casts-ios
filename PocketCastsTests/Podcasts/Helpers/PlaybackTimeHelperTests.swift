import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class PlaybackTimeHelperTests: XCTestCase {
    func testLastSevenDaysPlaytimeWhenNothingIsReturned() {
        let dataManagerMock = DataManagerMock()
        let playbackTimeHelper = PlaybackTimeHelper(dataManager: dataManagerMock)

        let playbackTime = playbackTimeHelper.playtimeLastSevenDaysInSeconds()

        XCTAssertEqual(playbackTime, 0)
    }
}

class DataManagerMock: DataManager {
    override func findEpisodesWhere(customWhere: String, arguments: [Any]?) -> [Episode] {
        return []
    }
}
