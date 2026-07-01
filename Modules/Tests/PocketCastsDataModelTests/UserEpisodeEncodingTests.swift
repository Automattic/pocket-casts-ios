import XCTest

@testable import PocketCastsDataModel

class UserEpisodeEncodingTests: XCTestCase {
    /// `hasCustomImage` must survive the encode/decode round-trip used to sync
    /// user episodes to the Watch. Regression test for a bug where
    /// `populateFromMap` decoded the literal key string `"hasCustomImage"`
    /// instead of `episodeMap["hasCustomImage"]`, so the flag was always `false`
    /// and custom-image user files showed placeholder artwork on the Watch.
    func testHasCustomImageSurvivesRoundTrip() {
        let episode = UserEpisode()
        episode.uuid = "test-uuid"
        episode.hasCustomImage = true

        let map = episode.encodeToMap()

        // Sanity check: the value is encoded correctly.
        XCTAssertEqual(map["hasCustomImage"], "true")

        let decoded = UserEpisode()
        decoded.populateFromMap(map)

        XCTAssertTrue(decoded.hasCustomImage, "hasCustomImage should be preserved through encode/decode")
    }
}
