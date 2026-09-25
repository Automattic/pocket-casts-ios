import XCTest
import GRDB
@testable import PocketCastsDataModel

final class DataManagerVacuumTests: DataManagerTestCase {

    func testVacuumDatabaseReclaimsFreePages() throws {
        try runWithDataManager { dataManager in
            try self.createFreePages(dataManager: dataManager)
            XCTAssertGreaterThan(try self.freelistCount(dataManager: dataManager), 0, "deleting rows should leave free pages")

            dataManager.vacuumDatabase()

            XCTAssertEqual(try self.freelistCount(dataManager: dataManager), 0, "vacuum should reclaim every free page")
        }
    }

    func testCleanUpReclaimsFreePages() throws {
        try runWithDataManager { dataManager in
            try self.createFreePages(dataManager: dataManager)
            XCTAssertGreaterThan(try self.freelistCount(dataManager: dataManager), 0, "deleting rows should leave free pages")

            dataManager.cleanUp()

            XCTAssertEqual(try self.freelistCount(dataManager: dataManager), 0, "cleanUp should end with a vacuum that reclaims every free page")
        }
    }

    func testVacuumDatabaseKeepsData() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(uuid: "podcast-1", dataManager: dataManager)
            self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)

            dataManager.vacuumDatabase(minimumFreePageRatio: 0)

            XCTAssertNotNil(dataManager.findPodcast(uuid: "podcast-1", includeUnsubscribed: true), "podcast should survive vacuum")
            XCTAssertNotNil(dataManager.findEpisode(uuid: "episode-1"), "episode should survive vacuum")
        }
    }

    func testVacuumDatabaseSkipsWhenFewPagesAreFree() throws {
        try runWithDataManager { dataManager in
            try self.createFreePages(dataManager: dataManager)
            let freePageRatio = try dataManager.dbQueue.freePageRatio()
            XCTAssertGreaterThan(freePageRatio, 0, "deleting rows should leave free pages")
            let freelistCount = try self.freelistCount(dataManager: dataManager)

            dataManager.vacuumDatabase(minimumFreePageRatio: freePageRatio + 0.01)

            XCTAssertEqual(try self.freelistCount(dataManager: dataManager), freelistCount, "vacuum should be skipped below the threshold")
        }
    }

    // MARK: - Helpers

    private func createFreePages(dataManager: DataManager) throws {
        let podcast = createTestPodcast(dataManager: dataManager)
        for index in 0..<200 {
            createTestEpisode(podcast: podcast, title: String(repeating: "Episode \(index) ", count: 50), dataManager: dataManager)
        }
        try dataManager.dbQueue.dbPool.write { db in
            try db.execute(sql: "DELETE FROM SJEpisode")
        }
    }

    private func freelistCount(dataManager: DataManager) throws -> Int {
        try dataManager.dbQueue.dbPool.read { db in
            try Int.fetchOne(db, sql: "PRAGMA freelist_count") ?? 0
        }
    }
}
