@testable import PocketCastsDataModel
import XCTest

final class PlaylistQueryBuilderTests: XCTestCase {

    func testQueryIncludesManualEpisodeUuids() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "manual-playlist"

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("WITH playlist AS"))
        XCTAssertTrue(query.contains("SELECT episodeUuid, MIN(episodePosition) AS pos"))
        XCTAssertTrue(query.contains("JOIN deduped_episode episode"))
        XCTAssertTrue(query.contains("playlist_uuid = 'manual-playlist'"))
    }

    func testQueryDoesNotIncludeEpisodesForSmartPlaylist() {
        let filter = EpisodeFilter()
        filter.manual = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertFalse(query.contains("WITH playlist AS"))
    }

    func testEmptyManualPlaylistDoesNotProduceInvalidInClause() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "empty-manual"

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }

    func testPodcastExistsQueryExcludesDeletedByDefault() {
        let query = PlaylistQueryBuilder.podcastExistsInPlaylistEpisodesQuery()

        XCTAssertTrue(query.contains("wasDeleted = 0"))
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query, values: ["1234"]))
    }

    func testPodcastExistsQueryIncludesDeletedWhenRequested() {
        let query = PlaylistQueryBuilder.podcastExistsInPlaylistEpisodesQuery(includeDeleted: true)

        XCTAssertFalse(query.contains("wasDeleted = 0"))
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query, values: ["1234"]))
    }
}
