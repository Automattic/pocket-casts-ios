import XCTest
import GRDB
@testable import PocketCastsDataModel

/// Checks that the episode queries every refresh and sync make use an index instead of reading every episode.
final class EpisodeIndexTests: DataManagerTestCase {

    func testLatestEpisodesQueryUsesThePodcastPublishedIndex() throws {
        try runWithDataManager { dataManager in
            let plan = try self.queryPlan(
                "SELECT * from \(DataManager.episodeTableName) WHERE podcast_id = ? AND wasDeleted = 0 ORDER BY publishedDate DESC, addedDate DESC LIMIT ?",
                arguments: [1, 1],
                dataManager: dataManager
            )

            XCTAssertTrue(plan.contains("episode_podcast_published"), plan)
            XCTAssertFalse(plan.contains("TEMP B-TREE"), plan)
        }
    }

    func testUnsyncedEpisodesQueryUsesTheUnsyncedIndex() throws {
        try runWithDataManager { dataManager in
            let plan = try self.queryPlan(
                "SELECT * from \(DataManager.episodeTableName) WHERE playingStatusModified > 0 OR playedUpToModified > 0 OR durationModified > 0 OR keepEpisodeModified > 0 OR archivedModified > 0 ORDER BY publishedDate DESC, addedDate DESC LIMIT 2000",
                dataManager: dataManager
            )

            XCTAssertTrue(plan.contains("episode_unsynced"), plan)
        }
    }

    private func queryPlan(_ sql: String, arguments: StatementArguments = [], dataManager: DataManager) throws -> String {
        try dataManager.dbQueue.dbPool.read { db in
            try Row.fetchAll(db, sql: "EXPLAIN QUERY PLAN \(sql)", arguments: arguments)
                .map { $0["detail"] as String }
                .joined(separator: "\n")
        }
    }
}
