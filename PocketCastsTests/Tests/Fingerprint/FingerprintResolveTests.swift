import XCTest

@testable import PocketCastsDataModel
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
    /// Everything here is below 1 kHz, so a lower rate costs the matcher nothing
    /// and keeps each resolve well inside its timeout.
    private static let sampleRate: Double = 16000

    /// A cue this far into the reference sits `adDuration` later in the listener's
    /// audio, because the ad has already played by then.
    private static let referenceCue: Double = 30
    private static var playbackCue: Double { referenceCue + adDuration }

    private var directory: URL!
    private var fixture: FingerprintEpisodeFixture!
    private var extraFixtures: [FingerprintEpisodeFixture] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FingerprintResolveTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let content = FingerprintFixtures.samples(seconds: Self.contentDuration, sampleRate: Self.sampleRate)
        let ad = FingerprintFixtures.samples(
            seconds: Self.adDuration,
            seed: FingerprintFixtures.adSeed,
            sampleRate: Self.sampleRate
        )
        let breakpoint = FingerprintFixtures.frameCount(forSeconds: Self.adStart, sampleRate: Self.sampleRate)

        fixture = FingerprintEpisodeFixture(duration: Self.contentDuration + Self.adDuration)

        // The reference is the publisher's copy — content only, no ad.
        let referenceAudioURL = directory.appendingPathComponent("reference-episode.wav")
        try FingerprintFixtures.writeAudio(content, sampleRate: Self.sampleRate, to: referenceAudioURL)
        try fixture.writeReference(forAudioAt: referenceAudioURL)

        // This listener's copy — the same content with the ad spliced in.
        try fixture.writeAudio(
            Array(content[0..<breakpoint]) + ad + Array(content[breakpoint...]),
            sampleRate: Self.sampleRate
        )
    }

    override func tearDown() {
        fixture?.removeFiles()
        fixture = nil
        extraFixtures.forEach { $0.removeFiles() }
        extraFixtures = []
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        super.tearDown()
    }

    /// Tapping a generated chapter: the chapter's time is on the reference
    /// timeline, and seeking there directly would land the listener before the
    /// content they asked for by the length of the ad.
    func testChapterResolveFindsTheAdShiftedPlaybackTime() async throws {
        let manager = FingerprintTimingManager()

        let result = await resolveChapter(manager, referenceTime: Self.referenceCue, episode: fixture.episode)

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
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
        XCTAssertEqual(manager.state.analyticsName, "idle")
    }

    /// The bookmark variant of the same resolve. It differs only in waiting for a
    /// streaming buffer, which a downloaded episode skips.
    func testBookmarkSeekResolveFindsTheAdShiftedPlaybackTime() async throws {
        let manager = FingerprintTimingManager()

        let result = await manager.resolveBookmarkPlaybackTime(
            forReferenceTime: Self.referenceCue,
            episode: fixture.episode
        )

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

        let referenceTime = await manager.resolveReferenceTime(
            forPlaybackTime: Self.playbackCue,
            episode: fixture.episode
        )

        XCTAssertEqual(try XCTUnwrap(referenceTime), Self.referenceCue, accuracy: 0.5)
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
    }

    /// A resolve against audio that isn't the reference's episode reports that it
    /// found nothing, rather than a confident wrong answer the player would seek to.
    func testChapterResolveReportsNoMatchForUnrelatedAudio() async throws {
        let unrelated = FingerprintEpisodeFixture(duration: Self.contentDuration)
        extraFixtures.append(unrelated)
        try unrelated.writeAudio(
            seconds: Self.contentDuration,
            seed: 0xAB_CD_EF_01,
            sampleRate: Self.sampleRate
        )
        // Same reference, different audio: the episode the listener has isn't the
        // one the reference was built from.
        try unrelated.writeReference(data: Data(contentsOf: fixture.referenceURL))

        let manager = FingerprintTimingManager()
        let result = await resolveChapter(manager, referenceTime: Self.referenceCue, episode: unrelated.episode)

        guard case .unresolved(let reason, _) = result else {
            XCTFail("expected an unresolved chapter seek, got \(result)")
            return
        }
        XCTAssertEqual(reason, "no_match")
    }

    /// The chapter resolve reports through a completion block, which is where the
    /// player's seek happens.
    private func resolveChapter(
        _ manager: FingerprintTimingManager,
        referenceTime: Double,
        episode: BaseEpisode
    ) async -> FingerprintTimingManager.ChapterSeekResult {
        await withCheckedContinuation { continuation in
            manager.resolvePlaybackTime(forReferenceTime: referenceTime, episode: episode) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
