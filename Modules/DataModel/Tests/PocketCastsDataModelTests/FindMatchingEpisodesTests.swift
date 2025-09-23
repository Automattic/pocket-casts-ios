@testable import PocketCastsDataModel
import XCTest

final class FindMatchingEpisodesTests: XCTestCase {
    func testFindMatchingEpisodesReturnsOnlyExisting() {
        let dm = DataManager.newTestDataManager()

        // Create two episodes that exist in DB
        let ep1 = Episode()
        ep1.uuid = "ep-1"
        ep1.podcastUuid = "pod-1"
        ep1.podcast_id = 1
        ep1.addedDate = Date()

        let ep2 = Episode()
        ep2.uuid = "ep-2"
        ep2.podcastUuid = "pod-2"
        ep2.podcast_id = 2
        ep2.addedDate = Date()

        dm.save(episode: ep1)
        dm.save(episode: ep2)

        let result = Set(dm.findMatchingEpisodes(uuids: ["ep-1", "missing", "ep-2"]))

        XCTAssertEqual(result, Set(["ep-1", "ep-2"]))
    }
}
