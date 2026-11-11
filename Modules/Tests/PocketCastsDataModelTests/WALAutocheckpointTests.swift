import XCTest
@testable import PocketCastsDataModel

final class WALAutocheckpointTests: DataManagerTestCase {
    private struct WorkError: Error {}

    func testPagesApplyOnlyWhileWorkRuns() throws {
        try runWithDataManager { dataManager in
            let pagesBefore = try dataManager.dbQueue.walAutocheckpoint()

            let pagesDuringWork = try dataManager.withWALAutocheckpoint(pages: 20_000) {
                try dataManager.dbQueue.walAutocheckpoint()
            }

            XCTAssertEqual(pagesBefore, 1000, "SQLite checkpoints every 1,000 pages by default")
            XCTAssertEqual(pagesDuringWork, 20_000)
            XCTAssertEqual(try dataManager.dbQueue.walAutocheckpoint(), pagesBefore)
        }
    }

    func testPagesAreRestoredWhenWorkThrows() throws {
        try runWithDataManager { dataManager in
            let pagesBefore = try dataManager.dbQueue.walAutocheckpoint()

            XCTAssertThrowsError(try dataManager.withWALAutocheckpoint(pages: 20_000) {
                throw WorkError()
            })

            XCTAssertEqual(try dataManager.dbQueue.walAutocheckpoint(), pagesBefore)
        }
    }

    func testWritesDuringWorkAreSaved() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)

            dataManager.withWALAutocheckpoint(pages: 20_000) {
                for _ in 0..<50 {
                    self.createTestEpisode(podcast: podcast, dataManager: dataManager)
                }
            }

            XCTAssertEqual(dataManager.findEpisodesWhere(customWhere: "podcast_id = ?", arguments: [podcast.id]).count, 50)
        }
    }
}
