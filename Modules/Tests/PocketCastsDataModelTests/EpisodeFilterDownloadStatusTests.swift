@testable import PocketCastsDataModel
import XCTest

final class EpisodeFilterDownloadStatusTests: XCTestCase {

    // MARK: - filtersByDownloadStatus

    func testDoesNotFilterByDownloadStatusWhenEveryStatusIsIncluded() {
        let filter = EpisodeFilter.makeDefault()

        XCTAssertFalse(filter.filtersByDownloadStatus)
    }

    func testFiltersByDownloadStatusWhenOnlyNotDownloadedIsIncluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false

        XCTAssertTrue(filter.filtersByDownloadStatus)
    }

    func testFiltersByDownloadStatusWhenOnlyDownloadedIsIncluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterNotDownloaded = false

        XCTAssertTrue(filter.filtersByDownloadStatus)
    }

    // MARK: - Query

    func testQueryHasNoDownloadStatusClauseWhenEveryStatusIsIncluded() throws {
        let filter = EpisodeFilter.makeDefault()

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testQueryExcludesDownloadedEpisodesWhenOnlyNotDownloadedIsIncluded() throws {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
    }

    func testQueryOnlyIncludesDownloadedEpisodesWhenOnlyDownloadedIsIncluded() throws {
        let filter = EpisodeFilter.makeDefault()
        filter.filterNotDownloaded = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testLegacyQueryHasNoDownloadStatusClauseWhenEveryStatusIsIncluded() {
        let filter = EpisodeFilter.makeDefault()

        let query = PlaylistQueryBuilder.queryFor(filter: filter, episodeUuidToAdd: nil, limit: 0)

        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testLegacyQueryExcludesDownloadedEpisodesWhenOnlyNotDownloadedIsIncluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false

        let query = PlaylistQueryBuilder.queryFor(filter: filter, episodeUuidToAdd: nil, limit: 0)

        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
    }
}
