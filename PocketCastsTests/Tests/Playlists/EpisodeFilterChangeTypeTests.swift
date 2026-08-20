import PocketCastsDataModel
import XCTest
@testable import podcasts

final class EpisodeFilterChangeTypeTests: XCTestCase {

    func testSmartPlaylistIsNotAffectedByDownloadStatusWhenEveryStatusIsIncluded() {
        let playlist = EpisodeFilter.makeDefault()

        XCTAssertFalse(playlist.isAffected(by: .downloadStatus))
    }

    func testSmartPlaylistIsAffectedByDownloadStatusWhenDownloadedIsExcluded() {
        let playlist = EpisodeFilter.makeDefault()
        playlist.filterDownloaded = false

        XCTAssertTrue(playlist.isAffected(by: .downloadStatus))
    }

    func testSmartPlaylistIsAffectedByDownloadStatusWhenNotDownloadedIsExcluded() {
        let playlist = EpisodeFilter.makeDefault()
        playlist.filterNotDownloaded = false

        XCTAssertTrue(playlist.isAffected(by: .downloadStatus))
    }

    func testSmartPlaylistIsAffectedByDownloadStatusWhenOnlyDownloadingIsIncluded() {
        let playlist = EpisodeFilter.makeDefault()
        playlist.filterDownloaded = false
        playlist.filterNotDownloaded = false

        XCTAssertTrue(playlist.isAffected(by: .downloadStatus))
    }

    func testManualPlaylistIsNotAffectedByDownloadStatus() {
        let playlist = EpisodeFilter.makeDefault()
        playlist.manual = true
        playlist.filterDownloaded = false

        XCTAssertFalse(playlist.isAffected(by: .downloadStatus))
    }

    func testPlaylistIsAffectedByArchiveChanges() {
        let playlist = EpisodeFilter.makeDefault()

        XCTAssertTrue(playlist.isAffected(by: .archived))
    }
}
