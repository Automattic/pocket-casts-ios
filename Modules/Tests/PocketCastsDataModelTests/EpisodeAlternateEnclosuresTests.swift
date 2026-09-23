import XCTest
@testable import PocketCastsDataModel

/// Tests for parsing the feed's `alternate_enclosures` tag into `Episode.hlsUrl`.
final class EpisodeAlternateEnclosuresTests: XCTestCase {

    // MARK: - Helper parsing

    func testExtractsHlsUrlFromAlternateEnclosures() {
        let json: [String: Any] = [
            "alternate_enclosures": [
                ["type": "application/x-mpegURL",
                 "sources": [["uri": "https://episode.example.com/hls/v/abc.m3u8"]]]
            ]
        ]

        XCTAssertEqual(Episode.hlsUrl(fromEpisodeJson: json), "https://episode.example.com/hls/v/abc.m3u8")
    }

    func testPicksHlsEnclosureAmongstMultipleTypes() {
        let json: [String: Any] = [
            "alternate_enclosures": [
                ["type": "audio/aac", "sources": [["uri": "https://example.com/audio.aac"]]],
                ["type": "application/x-mpegURL", "sources": [["uri": "https://example.com/stream.m3u8"]]]
            ]
        ]

        XCTAssertEqual(Episode.hlsUrl(fromEpisodeJson: json), "https://example.com/stream.m3u8")
    }

    func testMatchesHlsTypeCaseInsensitively() {
        let json: [String: Any] = [
            "alternate_enclosures": [
                ["type": "application/x-mpegurl",
                 "sources": [["uri": "https://example.com/stream.m3u8"]]]
            ]
        ]

        XCTAssertEqual(Episode.hlsUrl(fromEpisodeJson: json), "https://example.com/stream.m3u8")
    }

    /// Feeds advertise HLS under several types.
    func testMatchesEveryAdvertisedHlsType() {
        for type in ["application/x-mpegURL", "application/mpegURL", "application/vnd.apple.mpegurl"] {
            let json: [String: Any] = [
                "alternate_enclosures": [
                    ["type": type, "sources": [["uri": "https://example.com/stream.m3u8"]]]
                ]
            ]

            XCTAssertEqual(Episode.hlsUrl(fromEpisodeJson: json), "https://example.com/stream.m3u8", "failed for type \(type)")
        }
    }

    func testReturnsNilWhenNoHlsType() {
        let json: [String: Any] = [
            "alternate_enclosures": [
                ["type": "audio/aac", "sources": [["uri": "https://example.com/audio.aac"]]]
            ]
        ]

        XCTAssertNil(Episode.hlsUrl(fromEpisodeJson: json))
    }

    func testReturnsNilWhenAlternateEnclosuresMissing() {
        XCTAssertNil(Episode.hlsUrl(fromEpisodeJson: ["uuid": "abc"]))
    }

    func testReturnsNilWhenHlsEnclosureHasNoSources() {
        let json: [String: Any] = [
            "alternate_enclosures": [
                ["type": "application/x-mpegURL", "sources": [[String: Any]]()]
            ]
        ]

        XCTAssertNil(Episode.hlsUrl(fromEpisodeJson: json))
    }

    // MARK: - from(episodeJson:)

    func testFromEpisodeJsonPopulatesHlsUrl() {
        let json: [String: Any] = [
            "uuid": "episode-uuid",
            "url": "https://example.com/episode.mp3",
            "alternate_enclosures": [
                ["type": "application/x-mpegURL",
                 "sources": [["uri": "https://example.com/stream.m3u8"]]]
            ]
        ]

        let episode = Episode.from(episodeJson: json, podcastId: 1, podcastUuid: "podcast-uuid", isoFormatter: ISO8601DateFormatter())

        XCTAssertEqual(episode.hlsUrl, "https://example.com/stream.m3u8")
    }

    func testFromEpisodeJsonLeavesHlsUrlNilWhenAbsent() {
        let json: [String: Any] = [
            "uuid": "episode-uuid",
            "url": "https://example.com/episode.mp3"
        ]

        let episode = Episode.from(episodeJson: json, podcastId: 1, podcastUuid: "podcast-uuid", isoFormatter: ISO8601DateFormatter())

        XCTAssertNil(episode.hlsUrl)
    }
}
