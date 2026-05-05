import Foundation
@testable import PocketCastsSharedModels
import XCTest

final class SiriPodcastItemTests: XCTestCase {
    // SiriPodcastItem crosses the boundary between the main app and the
    // PodcastsIntents extension. The Codable contract is the wire format.
    func testRoundTripsThroughJSONCoding() throws {
        let original = SiriPodcastItem(name: "Podcast Name", uuid: "podcast-uuid")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SiriPodcastItem.self, from: data)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.uuid, original.uuid)
    }
}
