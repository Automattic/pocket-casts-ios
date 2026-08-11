import XCTest
@testable import podcasts
import PocketCastsDataModel

/// The capability table is the single place that states how the source kinds differ, and six
/// subsystems now read their behaviour from it. These pin each capability to the kinds it applies to.
final class PlaybackSourceTests: XCTestCase {

    private let allKinds: [PlaybackSource.Kind] = [.localFile, .progressive, .hls]

    func testOnlyHLSIsRateCappedAndNeedsExtraBuffering() {
        XCTAssertEqual(PlaybackSource.Kind.hls.maximumPlaybackSpeed, 2.0)
        XCTAssertEqual(PlaybackSource.Kind.hls.preferredForwardBufferDuration, 60)

        for kind in allKinds where kind != .hls {
            XCTAssertNil(kind.maximumPlaybackSpeed, "\(kind) should play at any rate the user has set")
            XCTAssertNil(kind.preferredForwardBufferDuration, "\(kind) should keep the AVPlayer default buffer")
        }
    }

    func testOnlyHLSRecoversFromStallsWithoutSeeking() {
        XCTAssertTrue(PlaybackSource.Kind.hls.recoversFromStallWithoutSeeking)

        for kind in allKinds where kind != .hls {
            XCTAssertFalse(kind.recoversFromStallWithoutSeeking, "\(kind) should recover from a stall by playing")
        }
    }

    func testOnlyHLSHidesItsTracks() {
        XCTAssertFalse(PlaybackSource.Kind.hls.exposesAudioTracks, "An audio processing tap can't attach to a manifest")
        XCTAssertFalse(PlaybackSource.Kind.hls.declaresVideoTracks, "Video has to be detected from the first decoded frame")

        for kind in allKinds where kind != .hls {
            XCTAssertTrue(kind.exposesAudioTracks, "\(kind) should support volume boost and the effects pipeline")
            XCTAssertTrue(kind.declaresVideoTracks, "\(kind) describes its own video up front")
        }
    }

    func testOnlyProgressiveCanBeCachedWhilePlaying() {
        XCTAssertTrue(PlaybackSource.Kind.progressive.isCacheable)

        XCTAssertFalse(PlaybackSource.Kind.hls.isCacheable, "A segmented manifest can't be byte-range cached")
        XCTAssertFalse(PlaybackSource.Kind.localFile.isCacheable, "A local file is already on disk")
    }

    func testOnlyHLSAdvertisesItsOwnContentType() {
        XCTAssertEqual(PlaybackSource.Kind.hls.advertisedContentType, Episode.advertisedHLSMimeType)

        for kind in allKinds where kind != .hls {
            XCTAssertNil(kind.advertisedContentType, "\(kind) should be advertised with the episode's own file type")
        }
    }
}
