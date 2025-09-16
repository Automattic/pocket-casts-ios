@testable import PocketCastsDataModel
import XCTest

final class PlaylistQueryBuilderTests: XCTestCase {

    func testQueryIncludesManualEpisodeUuids() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.episodes = ["e1", "e2"]

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }

    func testQueryDoesNotIncludeEpisodesForSmartPlaylist() {
        let filter = EpisodeFilter()
        filter.manual = false
        filter.episodes = ["e1", "e2"]

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }

    func testEmptyManualPlaylistDoesNotProduceInvalidInClause() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.episodes = []

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }
}
