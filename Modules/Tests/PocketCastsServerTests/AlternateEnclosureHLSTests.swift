import XCTest
@testable import PocketCastsServer
import PocketCastsDataModel

final class AlternateEnclosureHLSTests: XCTestCase {

    private func enclosure(type: String, uris: [String]) -> Api_AlternateEnclosure {
        var enclosure = Api_AlternateEnclosure()
        enclosure.type = type
        enclosure.sources = uris.map {
            var source = Api_AlternateEnclosure.Source()
            source.uri = $0
            return source
        }
        return enclosure
    }

    func testReturnsHLSUrlWhenPresent() {
        let enclosures = [enclosure(type: Episode.advertisedHLSMimeType, uris: ["https://example.com/stream.m3u8"])]
        XCTAssertEqual(enclosures.hlsUrl, "https://example.com/stream.m3u8")
    }

    func testTypeMatchIsCaseInsensitive() {
        let enclosures = [enclosure(type: "application/x-mpegurl", uris: ["https://example.com/stream.m3u8"])]
        XCTAssertEqual(enclosures.hlsUrl, "https://example.com/stream.m3u8")
    }

    /// Feeds advertise HLS under several types.
    func testMatchesEveryAdvertisedHLSType() {
        for type in ["application/x-mpegURL", "application/mpegURL", "application/vnd.apple.mpegurl"] {
            let enclosures = [enclosure(type: type, uris: ["https://example.com/stream.m3u8"])]
            XCTAssertEqual(enclosures.hlsUrl, "https://example.com/stream.m3u8", "failed for type \(type)")
        }
    }

    func testPicksHLSAmongOtherEnclosures() {
        let enclosures = [
            enclosure(type: "video/mp4", uris: ["https://example.com/video.mp4"]),
            enclosure(type: Episode.advertisedHLSMimeType, uris: ["https://example.com/stream.m3u8"])
        ]
        XCTAssertEqual(enclosures.hlsUrl, "https://example.com/stream.m3u8")
    }

    func testReturnsFirstSourceUri() {
        let enclosures = [enclosure(type: Episode.advertisedHLSMimeType, uris: ["https://a.example.com/1.m3u8", "https://b.example.com/2.m3u8"])]
        XCTAssertEqual(enclosures.hlsUrl, "https://a.example.com/1.m3u8")
    }

    func testReturnsNilWhenNoHLSEnclosure() {
        let enclosures = [enclosure(type: "video/mp4", uris: ["https://example.com/video.mp4"])]
        XCTAssertNil(enclosures.hlsUrl)
    }

    func testReturnsNilWhenEmpty() {
        XCTAssertNil([Api_AlternateEnclosure]().hlsUrl)
    }

    func testReturnsNilWhenHLSEnclosureHasNoSources() {
        let enclosures = [enclosure(type: Episode.advertisedHLSMimeType, uris: [])]
        XCTAssertNil(enclosures.hlsUrl)
    }
}
