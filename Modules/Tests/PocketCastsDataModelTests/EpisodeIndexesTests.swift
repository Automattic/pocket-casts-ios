import XCTest
import GRDB
@testable import PocketCastsDataModel

final class EpisodeIndexesTests: DataManagerTestCase {

    private let expectedIndexes: Set<String> = [
        "episode_uuid",
        "episode_podcast_uuid",
        "episode_podcast_id",
        "episode_pub_date",
        "episode_episodeStatus",
        "episode_non_null_download_task_id"
    ]

    func testEpisodeIndexes() throws {
        try runWithDataManager { dataManager in
            XCTAssertEqual(try self.episodeIndexes(dataManager: dataManager), self.expectedIndexes)
        }
    }

    func testCleanUpKeepsTheEpisodeIndexes() throws {
        try runWithDataManager { dataManager in
            dataManager.cleanUp()

            XCTAssertEqual(try self.episodeIndexes(dataManager: dataManager), self.expectedIndexes)
        }
    }

    // MARK: - Helpers

    private func episodeIndexes(dataManager: DataManager) throws -> Set<String> {
        try dataManager.dbQueue.dbPool.read { db in
            try Set(String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?", arguments: [DataManager.episodeTableName]))
        }
    }
}
