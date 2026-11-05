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

    // MARK: - Smart playlists

    func testRecentUnplayedPlaylistUsesThePublishedDateIndex() throws {
        let playlist = makeSmartPlaylist(unplayed: true, inProgress: true, hours: 336)

        for clause in [PlaylistQueryBuilder.SelectClause.episode, .firstDistinctEpisodes, .episodeCount] {
            let plan = try queryPlan(PlaylistQueryBuilder.query(clause: clause, for: playlist, limit: 100))

            XCTAssertTrue(plan.contains("episode_pub_date"), "\(clause): \(plan)")
            XCTAssertFalse(plan.contains("episode_playingStatus"), "\(clause): \(plan)")
        }
    }

    func testLegacyRecentUnplayedPlaylistUsesThePublishedDateIndex() throws {
        let playlist = makeSmartPlaylist(unplayed: true, inProgress: true, hours: 336)

        let query = "SELECT * FROM \(DataManager.episodeTableName) WHERE \(PlaylistQueryBuilder.queryFor(filter: playlist, episodeUuidToAdd: nil, limit: 100))"
        let plan = try queryPlan(query)

        XCTAssertTrue(plan.contains("episode_pub_date"), plan)
        XCTAssertFalse(plan.contains("episode_playingStatus"), plan)
    }

    func testUnplayedPlaylistCountDoesNotReadEpisodesInUuidOrder() throws {
        let playlist = makeSmartPlaylist(unplayed: true, inProgress: false, hours: 0)

        let plan = try queryPlan(PlaylistQueryBuilder.query(clause: .episodeCount, for: playlist))

        XCTAssertFalse(plan.contains("episode_uuid"), plan)
        XCTAssertFalse(plan.contains("episode_playingStatus"), plan)
    }

    func testInProgressPlaylistKeepsThePlayingStatusIndex() throws {
        let playlist = makeSmartPlaylist(unplayed: false, inProgress: true, hours: 744)

        for clause in [PlaylistQueryBuilder.SelectClause.episode, .firstDistinctEpisodes, .episodeCount] {
            let plan = try queryPlan(PlaylistQueryBuilder.query(clause: clause, for: playlist, limit: 100))

            XCTAssertTrue(plan.contains("episode_playingStatus"), "\(clause): \(plan)")
        }
    }

    // MARK: - Helpers

    private func makeSmartPlaylist(unplayed: Bool, inProgress: Bool, hours: Int32) -> EpisodeFilter {
        let playlist = EpisodeFilter.makeDefault()
        playlist.filterUnplayed = unplayed
        playlist.filterPartiallyPlayed = inProgress
        playlist.filterFinished = false
        playlist.filterHours = hours
        playlist.sortType = PlaylistSort.newestToOldest.rawValue
        return playlist
    }

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
