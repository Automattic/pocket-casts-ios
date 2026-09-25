@testable import PocketCastsDataModel
import XCTest

final class EpisodeFilterRenameTests: XCTestCase {
    func testRenameUpdatesName() {
        let filter = EpisodeFilter.makeDefault()
        filter.playlistName = "Morning Commute"

        filter.rename(to: "Evening Walk")

        XCTAssertEqual(filter.playlistName, "Evening Walk")
    }

    func testRenameToEmptyKeepsPreviousName() {
        let filter = EpisodeFilter.makeDefault()
        filter.playlistName = "Morning Commute"

        filter.rename(to: "")

        XCTAssertEqual(filter.playlistName, "Morning Commute")
    }

    func testRenameToWhitespaceKeepsPreviousName() {
        let filter = EpisodeFilter.makeDefault()
        filter.playlistName = "Morning Commute"

        filter.rename(to: "   \n")

        XCTAssertEqual(filter.playlistName, "Morning Commute")
    }

    func testRenameToNilKeepsPreviousName() {
        let filter = EpisodeFilter.makeDefault()
        filter.playlistName = "Morning Commute"

        filter.rename(to: nil)

        XCTAssertEqual(filter.playlistName, "Morning Commute")
    }
}
