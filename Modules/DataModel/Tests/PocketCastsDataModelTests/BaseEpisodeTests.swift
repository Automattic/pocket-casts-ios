import XCTest

@testable import PocketCastsDataModel

class BaseEpisodeTests: XCTestCase {
    func testSelectAChapter() {
        let episode = Episode()
        episode.deselectedChapters = "0,1,2,3"

        episode.select(chapterIndex: 0)

        XCTAssertEqual(episode.deselectedChapters, "1,2,3")
    }

    func testDeselectAChapter() {
        let episode = Episode()
        episode.deselectedChapters = "0,1,2,3"

        episode.deselect(chapterIndex: 4)

        XCTAssertEqual(episode.deselectedChapters, "0,1,2,3,4")
    }

    func testDontDeselectAChapterTwice() {
        let episode = Episode()
        episode.deselectedChapters = "0,1,2,3"

        episode.deselect(chapterIndex: 0)

        XCTAssertEqual(episode.deselectedChapters, "0,1,2,3")
    }
}
