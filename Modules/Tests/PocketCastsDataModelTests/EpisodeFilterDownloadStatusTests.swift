@testable import PocketCastsDataModel
import XCTest

final class EpisodeFilterDownloadStatusTests: XCTestCase {

    // MARK: - filtersByDownloadStatus

    func testDoesNotFilterByDownloadStatusWhenEveryStatusIsIncluded() {
        let filter = EpisodeFilter.makeDefault()

        XCTAssertFalse(filter.filtersByDownloadStatus)
    }

    func testFiltersByDownloadStatusWhenDownloadedIsExcluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false

        XCTAssertTrue(filter.filtersByDownloadStatus)
    }

    func testFiltersByDownloadStatusWhenNotDownloadedIsExcluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterNotDownloaded = false

        XCTAssertTrue(filter.filtersByDownloadStatus)
    }

    func testFiltersByDownloadStatusWhenOnlyDownloadingIsIncluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false
        filter.filterNotDownloaded = false

        XCTAssertTrue(filter.filtersByDownloadStatus)
    }

    // MARK: - Query

    func testQueryHasNoDownloadStatusClauseWhenEveryStatusIsIncluded() throws {
        let filter = EpisodeFilter.makeDefault()

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testQueryStillMatchesDownloadingEpisodesWhenDownloadedIsExcluded() throws {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.downloading.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
    }

    func testQueryStillMatchesDownloadingEpisodesWhenNotDownloadedIsExcluded() throws {
        let filter = EpisodeFilter.makeDefault()
        filter.filterNotDownloaded = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.downloading.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testQueryOnlyMatchesDownloadingEpisodesWhenOnlyDownloadingIsIncluded() throws {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false
        filter.filterNotDownloaded = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.downloading.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testLegacyQueryHasNoDownloadStatusClauseWhenEveryStatusIsIncluded() {
        let filter = EpisodeFilter.makeDefault()

        let query = PlaylistQueryBuilder.queryFor(filter: filter, episodeUuidToAdd: nil, limit: 0)

        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }

    func testLegacyQueryStillMatchesDownloadingEpisodesWhenDownloadedIsExcluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false

        let query = PlaylistQueryBuilder.queryFor(filter: filter, episodeUuidToAdd: nil, limit: 0)

        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
    }

    func testLegacyQueryOnlyMatchesDownloadingEpisodesWhenOnlyDownloadingIsIncluded() {
        let filter = EpisodeFilter.makeDefault()
        filter.filterDownloaded = false
        filter.filterNotDownloaded = false

        let query = PlaylistQueryBuilder.queryFor(filter: filter, episodeUuidToAdd: nil, limit: 0)

        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.queued.rawValue)"))
        XCTAssertTrue(query.contains("episodeStatus = \(DownloadStatus.downloading.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.downloaded.rawValue)"))
        XCTAssertFalse(query.contains("episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)"))
    }
}
