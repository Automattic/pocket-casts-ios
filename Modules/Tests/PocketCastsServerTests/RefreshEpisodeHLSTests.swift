import XCTest
@testable import PocketCastsServer
import PocketCastsDataModel

/// Tests decoding refresh-server's `alternate_enclosures` (added in refresh-server#596) into
/// `RefreshEpisode.hlsUrl`, which feeds `Episode.populate(fromEpisode:)` on the incremental refresh path.
final class RefreshEpisodeHLSTests: XCTestCase {

    private func decode(_ json: String) throws -> RefreshEpisode {
        try JSONDecoder().decode(RefreshEpisode.self, from: Data(json.utf8))
    }

    func testDecodesHlsUrlFromAlternateEnclosures() throws {
        let episode = try decode("""
        { "uuid": "abc", "url": "https://example.com/ep.mp3",
          "alternate_enclosures": [
            { "type": "application/x-mpegurl", "sources": [{ "uri": "https://example.com/master.m3u8" }] }
          ] }
        """)
        XCTAssertEqual(episode.hlsUrl, "https://example.com/master.m3u8")
    }

    func testPicksHlsAmongOtherEnclosures() throws {
        let episode = try decode("""
        { "uuid": "abc",
          "alternate_enclosures": [
            { "type": "video/mp4", "sources": [{ "uri": "https://example.com/v.mp4" }] },
            { "type": "application/x-mpegURL", "sources": [{ "uri": "https://example.com/master.m3u8" }] }
          ] }
        """)
        XCTAssertEqual(episode.hlsUrl, "https://example.com/master.m3u8")
    }

    func testNilWhenNoAlternateEnclosures() throws {
        let episode = try decode(#"{ "uuid": "abc", "url": "https://example.com/ep.mp3" }"#)
        XCTAssertNil(episode.hlsUrl)
    }

    func testNilWhenNoHlsType() throws {
        let episode = try decode("""
        { "uuid": "abc",
          "alternate_enclosures": [
            { "type": "audio/aac", "sources": [{ "uri": "https://example.com/a.aac" }] }
          ] }
        """)
        XCTAssertNil(episode.hlsUrl)
    }

    func testNilWhenHlsEnclosureHasNoSources() throws {
        let episode = try decode("""
        { "uuid": "abc",
          "alternate_enclosures": [ { "type": "application/x-mpegurl", "sources": [] } ] }
        """)
        XCTAssertNil(episode.hlsUrl)
    }
}
