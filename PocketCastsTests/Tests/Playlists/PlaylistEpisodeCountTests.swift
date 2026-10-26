import XCTest
@testable import podcasts

final class PlaylistEpisodeCountTests: XCTestCase {
    func testOneEpisodeUsesSingularForm() {
        XCTAssertEqual(L10n.playlistEpisodeCount(1), L10n.podcastEpisodeCountSingular)
    }

    func testOtherCountsUsePluralForm() {
        XCTAssertEqual(L10n.playlistEpisodeCount(0), L10n.playlistEpisodesCount(0))
        XCTAssertEqual(L10n.playlistEpisodeCount(5), L10n.playlistEpisodesCount(5))
    }
}
