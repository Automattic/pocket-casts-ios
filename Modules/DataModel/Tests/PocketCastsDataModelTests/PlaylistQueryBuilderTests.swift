@testable import PocketCastsDataModel
import XCTest

final class PlaylistQueryBuilderTests: XCTestCase {

    func testQueryIncludesManualEpisodeUuids() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "manual-playlist"

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("episode.uuid IN (SELECT DISTINCT episodeUuid"))
        XCTAssertTrue(query.contains("playlist_uuid = 'manual-playlist'"))
    }

    func testQueryDoesNotIncludeEpisodesForSmartPlaylist() {
        let filter = EpisodeFilter()
        filter.manual = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertFalse(query.contains("episode.uuid IN (SELECT DISTINCT episodeUuid"))
    }

    func testEmptyManualPlaylistDoesNotProduceInvalidInClause() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "empty-manual"

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }
}
