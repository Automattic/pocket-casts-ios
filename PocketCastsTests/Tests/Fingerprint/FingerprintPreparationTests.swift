import XCTest

@testable import podcasts

/// End-to-end coverage of preparation: a reference fingerprint on disk, a real
/// decode of a real audio file, the real matcher, and the real drift filter. Only
/// the episode's audio and its reference are synthesized — and the reference is
/// built from that same audio, so a correct run maps every anchor onto its own
/// timestamp and any drift shows up as an assertion failure.
@MainActor
final class FingerprintPreparationTests: XCTestCase {

    /// Long enough to commit anchors across the whole file: the first window can't
    /// be emitted until 8 s of audio have been decoded, and the drift filter needs
    /// three consecutive in-trend candidates before it commits anything.
    private static let episodeDuration: Double = 45

    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FingerprintPreparationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        try super.tearDownWithError()
    }

    func testPreparationMapsDownloadedEpisodeOntoItsReference() async throws {
        let audioURL = directory.appendingPathComponent("episode.caf")
        try FingerprintFixtures.writeAudio(seconds: Self.episodeDuration, to: audioURL)

        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.makeReference(forAudioAt: audioURL).write(to: referenceURL)

        let manager = FingerprintTimingManager()
        await manager.testing.prepare(request: Self.request(audio: audioURL, reference: referenceURL))

        // Reference decoded and the matcher built, so the stream is running. No
        // commit can have landed yet — they need the main actor, and we haven't
        // suspended since `prepare` returned.
        XCTAssertEqual(manager.state.analyticsName, "preparing")
        XCTAssertTrue(manager.snapshot.isEmpty)

        await manager.testing.waitForStream()

        guard case .active(let coverage) = manager.state else {
            XCTFail("expected .active after a full pass, got \(manager.state)")
            return
        }

        let entries = manager.snapshot.playbackToReference
        XCTAssertEqual(coverage, entries.count)
        // Windows are emitted every second but the reference's checkpoints sit every
        // two, so the off-grid windows straddle a pair and are dropped by the
        // dominance gate. What's left is one anchor per checkpoint — 19 of them in a
        // 45 s file, allowing a few to fall out at the edges.
        XCTAssertGreaterThanOrEqual(entries.count, 15)

        // The reference was built from this exact audio, so an anchor with a
        // checkpoint at its own timestamp should map onto itself. A window that
        // matched a neighbouring checkpoint instead would still pass the drift
        // filter (rate 1, just offset), and would show up here. The last window
        // starts within a window's length of the end, where the checkpoint grid has
        // run out — nothing exact is left for it, so it settles for the nearest.
        let gridEnd = Self.episodeDuration - Double(FingerprintFixtures.checkpointDurationSeconds)
        for entry in entries {
            XCTAssertEqual(
                entry.referenceTime,
                entry.playbackTime,
                accuracy: entry.playbackTime < gridEnd ? 0.001 : Double(FingerprintFixtures.checkpointIntervalSeconds),
                "anchor at playback \(entry.playbackTime)s mapped to reference \(entry.referenceTime)s"
            )
            XCTAssertGreaterThanOrEqual(entry.score, FingerprintConstants.driftAnchorScoreThreshold)
        }

        // Coverage reaches both ends of the file, not just the region around the
        // first few chunks.
        XCTAssertLessThanOrEqual(try XCTUnwrap(entries.first).playbackTime, 4)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(entries.last).playbackTime, gridEnd - 4)

        // Both sorted views hold the same anchors, each in its own order.
        XCTAssertEqual(manager.snapshot.referenceToPlayback.count, entries.count)
        XCTAssertEqual(entries.map(\.playbackTime), entries.map(\.playbackTime).sorted())
        XCTAssertEqual(
            manager.snapshot.referenceToPlayback.map(\.referenceTime),
            manager.snapshot.referenceToPlayback.map(\.referenceTime).sorted()
        )

        // What the transcript UI actually calls: mid-episode is matched content,
        // and both directions agree there.
        let midpoint = Self.episodeDuration / 2
        XCTAssertTrue(manager.isWithinMatchedContent(forPlaybackTime: midpoint))
        XCTAssertEqual(try XCTUnwrap(manager.matchedReferenceTime(forPlaybackTime: midpoint)), midpoint, accuracy: 0.5)
        XCTAssertEqual(try XCTUnwrap(manager.playbackTime(forReferenceTime: midpoint)), midpoint, accuracy: 0.5)
    }

    /// A pass that reaches the end of the file having found nothing it trusts is
    /// "we couldn't map this episode", not a decode failure — the two report
    /// different analytics, and only the clean ending persists a mapping cache.
    func testPreparationEndsUnavailableWhenAudioDoesNotMatchTheReference() async throws {
        let audioURL = directory.appendingPathComponent("episode.caf")
        try FingerprintFixtures.writeAudio(seconds: Self.episodeDuration, to: audioURL)

        // A reference built from a different episode entirely.
        let otherAudioURL = directory.appendingPathComponent("other-episode.caf")
        try FingerprintFixtures.writeAudio(seconds: Self.episodeDuration, seed: 0x2C_0F_FE_E1, to: otherAudioURL)
        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.makeReference(forAudioAt: otherAudioURL).write(to: referenceURL)

        let manager = FingerprintTimingManager()
        await manager.testing.prepare(request: Self.request(audio: audioURL, reference: referenceURL))
        await manager.testing.waitForStream()

        XCTAssertEqual(manager.state.analyticsName, "unavailable")
        XCTAssertTrue(manager.snapshot.isEmpty)
    }

    private static func request(audio: URL, reference: URL) -> FingerprintTimingManager.EpisodeRequest {
        FingerprintTimingManager.EpisodeRequest(
            episodeUuid: "episode-uuid",
            podcastUuid: "podcast-uuid",
            duration: episodeDuration,
            audioFileURL: audio,
            isStreaming: false,
            referenceFilePath: reference.path
        )
    }
}
