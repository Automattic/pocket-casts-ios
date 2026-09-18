import PocketCastsLocalization
import XCTest

final class L10nTests: XCTestCase {
    func testFallsBackToEnglishWithoutAppStrings() {
        XCTAssertEqual(L10n.aboutWebsite, "Website")
        XCTAssertEqual(L10n.seasonEpisodeShorthand(seasonNumber: 2, episodeNumber: 5), "S2 E5")
    }
}
