import Foundation
@testable import podcasts
import XCTest

final class CommonUpNextItemTests: XCTestCase {
    // CommonUpNextItem crosses process boundaries via App Group UserDefaults
    // (main app writes, widget/intents extension reads). The Codable contract
    // is the wire format — guard it explicitly.
    func testRoundTripsThroughJSONCoding() throws {
        let original = CommonUpNextItem(
            episodeUuid: "episode-uuid",
            imageUrl: "https://example.com/image.png",
            episodeTitle: "Episode Title",
            podcastName: "Podcast Name",
            podcastColor: "#FF0000",
            duration: 1234.5,
            isPlaying: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CommonUpNextItem.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testRoundTripsWhenNotPlaying() throws {
        let original = CommonUpNextItem(
            episodeUuid: "uuid",
            imageUrl: "url",
            episodeTitle: "title",
            podcastName: "name",
            podcastColor: "color",
            duration: 0,
            isPlaying: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CommonUpNextItem.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}
