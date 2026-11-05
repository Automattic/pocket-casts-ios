import XCTest
import GRDB
@testable import PocketCastsDataModel
import PocketCastsUtils

/// Checks that episode queries with `IndexHint.skipIndex(_:)` look rows up with a selective index.
final class EpisodeQueryIndexHintTests: DataManagerTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FeatureFlagOverrideStore().override(FeatureFlag.episodeQueryIndexHints, withValue: true)
    }

    override func tearDown() {
        FeatureFlagOverrideStore().resetOverrides()
        super.tearDown()
    }

    func testSearchInPodcastUsesThePodcastIndex() throws {
        let query = "SELECT * FROM \(DataManager.episodeTableName) WHERE \(EpisodeDataManager.findEpisodesWithTermWhereClause())"

        let plan = try queryPlan(query, arguments: ["term", "podcast-uuid"])

        XCTAssertTrue(plan.contains("episode_podcast_uuid"), plan)
        XCTAssertFalse(plan.contains("episode_was_deleted"), plan)
    }

    // MARK: - Helpers

    private func queryPlan(_ query: String, arguments: StatementArguments = []) throws -> String {
        var plan = ""
        try runWithDataManager { dataManager in
            plan = try dataManager.dbQueue.dbPool.read { db in
                try Row.fetchAll(db, sql: "EXPLAIN QUERY PLAN \(query)", arguments: arguments)
                    .map { $0["detail"] as String }
                    .joined(separator: "\n")
            }
        }
        return plan
    }
}
