import XCTest

@testable import podcasts

/// The one-shot resolves — a tapped chapter and a played bookmark — against an
/// episode whose audio carries a dynamic ad the reference doesn't. Both run the
/// real bounded decode and matcher; only the audio and its reference are
/// synthesized.
@MainActor
final class FingerprintResolveTests: XCTestCase {

    private static let contentDuration: Double = 45
    private static let adStart: Double = 20
    private static let adDuration: Double = 10

    /// A cue this far into the reference sits `adDuration` later in the listener's
    /// audio, because the ad has already played by then.
    private static let referenceCue: Double = 30
    private static var playbackCue: Double { referenceCue + adDuration }

    private var directory: URL!
    private var audioURL: URL!
    private var referenceURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FingerprintResolveTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let content = FingerprintFixtures.samples(seconds: Self.contentDuration)
        let ad = FingerprintFixtures.samples(seconds: Self.adDuration, seed: FingerprintFixtures.adSeed)
        let breakpoint = FingerprintFixtures.frameCount(forSeconds: Self.adStart)

        let referenceAudioURL = directory.appendingPathComponent("reference-episode.caf")
        try FingerprintFixtures.writeAudio(content, to: referenceAudioURL)
        referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.makeReference(forAudioAt: referenceAudioURL).write(to: referenceURL)

        audioURL = directory.appendingPathComponent("episode.caf")
        try FingerprintFixtures.writeAudio(
            Array(content[0..<breakpoint]) + ad + Array(content[breakpoint...]),
            to: audioURL
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        audioURL = nil
        referenceURL = nil
        try super.tearDownWithError()
    }

    /// Tapping a generated chapter: the chapter's time is on the reference
    /// timeline, and seeking there directly would land the listener before the
    /// content they asked for by the length of the ad.
    func testChapterResolveFindsTheAdShiftedPlaybackTime() async throws {
        let manager = FingerprintTimingManager()

        let result = await manager.testing.resolveChapter(request: request(), referenceTime: Self.referenceCue)

        guard case .resolved(let playbackTime, let usedPrior, let isStreaming, _) = result else {
            XCTFail("expected a resolved chapter seek, got \(result)")
            return
        }
        XCTAssertEqual(playbackTime, Self.playbackCue, accuracy: 0.5)
        // Cold path: no continuous mapping exists to warm-start from.
        XCTAssertFalse(usedPrior)
        XCTAssertFalse(isStreaming)

        // A one-shot resolve matches into its own scratch mapping. Nothing the
        // transcript highlighter reads may have moved.
        XCTAssertTrue(manager.snapshot.isEmpty)
        XCTAssertEqual(manager.state.analyticsName, "idle")
    }

    /// The bookmark variant of the same resolve. It differs only in waiting for a
    /// streaming buffer, which a downloaded episode skips.
    func testBookmarkSeekResolveFindsTheAdShiftedPlaybackTime() async throws {
        let manager = FingerprintTimingManager()

        let result = await manager.testing.resolveBookmark(request: request(), referenceTime: Self.referenceCue)

        guard case .resolved(let playbackTime, _, _, _) = result else {
            XCTFail("expected a resolved bookmark seek, got \(result)")
            return
        }
        XCTAssertEqual(playbackTime, Self.playbackCue, accuracy: 0.5)
    }

    /// The opposite direction: a bookmark is stored at a position in this
    /// listener's audio, and reading the transcript at that moment needs the
    /// reference time it corresponds to.
    func testBookmarkReferenceResolveMapsPlaybackBackOntoTheReference() async throws {
        let manager = FingerprintTimingManager()

        let referenceTime = await manager.testing.resolveReference(
            request: request(),
            playbackTime: Self.playbackCue
        )

        XCTAssertEqual(try XCTUnwrap(referenceTime), Self.referenceCue, accuracy: 0.5)
        XCTAssertTrue(manager.snapshot.isEmpty)
    }

    /// A resolve against audio that isn't the reference's episode reports that it
    /// found nothing, rather than a confident wrong answer the player would seek to.
    func testChapterResolveReportsNoMatchForUnrelatedAudio() async throws {
        let unrelatedURL = directory.appendingPathComponent("unrelated.caf")
        try FingerprintFixtures.writeAudio(seconds: Self.contentDuration, seed: 0xAB_CD_EF_01, to: unrelatedURL)

        let manager = FingerprintTimingManager()
        let result = await manager.testing.resolveChapter(
            request: request(audio: unrelatedURL),
            referenceTime: Self.referenceCue
        )

        guard case .unresolved(let reason, _) = result else {
            XCTFail("expected an unresolved chapter seek, got \(result)")
            return
        }
        XCTAssertEqual(reason, "no_match")
    }

    private func request(audio: URL? = nil) -> FingerprintTimingManager.EpisodeRequest {
        FingerprintTimingManager.EpisodeRequest(
            episodeUuid: "episode-uuid",
            podcastUuid: "podcast-uuid",
            duration: Self.contentDuration + Self.adDuration,
            audioFileURL: audio ?? audioURL,
            isStreaming: false,
            referenceFilePath: referenceURL.path
        )
    }
}
