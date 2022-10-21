import XCTest

@testable import podcasts
@testable import PocketCastsDataModel

class EndOfYearStoriesBuilderTests: XCTestCase {
    func testReturnListeningTimeStoryIfBiggerThanZero() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listeningTimeToReturn = 3000
        let stories = await builder.build()

        XCTAssertEqual(stories.0.first, EndOfYearStory.listeningTime)
        XCTAssertEqual(stories.1.listeningTime, 3000)
    }
}
