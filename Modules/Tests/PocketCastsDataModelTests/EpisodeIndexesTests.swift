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
        "episode_non_null_download_task_id",
        "episode_unarchived"
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

    func testUnarchivedIndexCoversOnlyUnarchivedEpisodes() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            for index in 0..<10 {
                let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
                episode.archived = index >= 3
                dataManager.save(episode: episode)
            }

            let indexed = try dataManager.dbQueue.dbPool.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(DataManager.episodeTableName) INDEXED BY episode_unarchived WHERE archived = 0") ?? 0
            }
            XCTAssertEqual(indexed, 3)

            let indexSql = try dataManager.dbQueue.dbPool.read { db in
                try String.fetchOne(db, sql: "SELECT sql FROM sqlite_master WHERE type = 'index' AND name = 'episode_unarchived'")
            }
            XCTAssertEqual(indexSql, "CREATE INDEX episode_unarchived ON SJEpisode (episodeStatus, playingStatus) WHERE archived = 0")
        }
    }

    func testMigratingFromSchema78AddsTheUnarchivedIndex() throws {
        try runWithDataManager { dataManager in
            try dataManager.dbQueue.dbPool.write { db in
                try db.execute(sql: "DROP INDEX episode_unarchived")
                try db.execute(sql: "PRAGMA user_version = 78")
            }
            XCTAssertFalse(try self.episodeIndexes(dataManager: dataManager).contains("episode_unarchived"))

            DatabaseHelper.setup(queue: dataManager.dbQueue)

            XCTAssertEqual(try self.episodeIndexes(dataManager: dataManager), self.expectedIndexes)
            let version = try dataManager.dbQueue.dbPool.read { try Int.fetchOne($0, sql: "PRAGMA user_version") }
            XCTAssertEqual(version, 79)
        }
    }

    // MARK: - Helpers

    private func episodeIndexes(dataManager: DataManager) throws -> Set<String> {
        try dataManager.dbQueue.dbPool.read { db in
            try Set(String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?", arguments: [DataManager.episodeTableName]))
        }
    }
}
