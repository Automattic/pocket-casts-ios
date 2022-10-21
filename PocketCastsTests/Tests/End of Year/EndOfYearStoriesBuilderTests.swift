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

        XCTAssertFalse(stories.0.contains(.listeningTime))
        XCTAssertEqual(stories.1.listeningTime, 3000)
    }

    func testDontReturnListeningTimeStoryIfZero() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listeningTimeToReturn = 0
        let stories = await builder.build()

        XCTAssertFalse(stories.0.contains(.listeningTime))
        XCTAssertEqual(stories.1.listeningTime, 0)
    }

    func testReturnListenedCategories() async {
        let endOfYearManager = EndOfYearManagerMock()
        let dataManager = DataManagerMock(endOfYearManager: endOfYearManager)
        let builder = EndOfYearStoriesBuilder(dataManager: dataManager)

        endOfYearManager.listenedCategoriesToReturn = [
            ListenedCategory(numberOfPodcasts: 1, categoryTitle: "title")
        ]
        let stories = await builder.build()

        XCTAssertEqual(stories.0.first, EndOfYearStory.listenedCategories)
        XCTAssertEqual(stories.0[1], EndOfYearStory.topFiveCategories)
        XCTAssertEqual(stories.1.listenedCategories.first?.numberOfPodcasts, 1)
        XCTAssertEqual(stories.1.listenedCategories.first?.numberOfPodcasts, 1)
    }
}
