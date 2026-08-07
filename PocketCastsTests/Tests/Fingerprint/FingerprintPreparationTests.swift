import XCTest

@testable import PocketCastsUtils
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

    /// The dynamic-ad fixture: a 10 s ad spliced 20 s into a 45 s episode.
    private static let contentDuration: Double = 45
    private static let adStart: Double = 20
    private static let adDuration: Double = 10
    private static var adEnd: Double { adStart + adDuration }

    private var directory: URL!
    private let featureFlags = FeatureFlagMock()

    override func setUpWithError() throws {
        try super.setUpWithError()
        // A pass starts wherever the listener is. Left alone, that's whatever the
        // host app's persisted Up Next happens to hold, which would offset every
        // anchor by that episode's position — nothing is playing in these tests.
        PlaybackManager.shared.queue = PlaybackQueue()
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FingerprintPreparationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        featureFlags.reset()
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

    /// The case the whole subsystem exists for: this listener's copy has a dynamic
    /// ad the reference doesn't, so everything after it sits later in the audio than
    /// the transcript says. The mapping has to absorb that shift, and highlighting
    /// has to switch off while the ad plays.
    func testPreparationAbsorbsADynamicAdInsertedIntoTheEpisode() async throws {
        let content = FingerprintFixtures.samples(seconds: Self.contentDuration)
        let ad = FingerprintFixtures.samples(seconds: Self.adDuration, seed: FingerprintFixtures.adSeed)
        let breakpoint = FingerprintFixtures.frameCount(forSeconds: Self.adStart)

        // The reference is the publisher's copy — content only, no ad.
        let referenceAudioURL = directory.appendingPathComponent("reference-episode.caf")
        try FingerprintFixtures.writeAudio(content, to: referenceAudioURL)
        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.makeReference(forAudioAt: referenceAudioURL).write(to: referenceURL)

        // This listener's copy — the same content with the ad spliced in.
        let audioURL = directory.appendingPathComponent("episode.caf")
        try FingerprintFixtures.writeAudio(
            Array(content[0..<breakpoint]) + ad + Array(content[breakpoint...]),
            to: audioURL
        )

        let manager = FingerprintTimingManager()
        await manager.testing.prepare(request: Self.request(
            audio: audioURL,
            reference: referenceURL,
            duration: Self.contentDuration + Self.adDuration
        ))
        await manager.testing.waitForStream()

        XCTAssertEqual(manager.state.analyticsName, "active")
        let entries = manager.snapshot.playbackToReference
        XCTAssertFalse(entries.isEmpty)

        // Every anchor sits either before the ad (no shift yet) or after it (shifted
        // by the ad's whole length). Anything in between never anchors: those windows
        // straddle the splice and match nothing.
        let gridEnd = Self.contentDuration - Double(FingerprintFixtures.checkpointDurationSeconds)
        for entry in entries {
            let shift = entry.playbackTime < Self.adStart ? 0 : Self.adDuration
            let expected = entry.playbackTime - shift
            XCTAssertEqual(
                entry.referenceTime,
                expected,
                accuracy: expected < gridEnd ? 0.001 : Double(FingerprintFixtures.checkpointIntervalSeconds),
                "anchor at playback \(entry.playbackTime)s mapped to reference \(entry.referenceTime)s"
            )
        }
        XCTAssertTrue(entries.contains { $0.playbackTime < Self.adStart }, "nothing anchored before the ad")
        XCTAssertTrue(entries.contains { $0.playbackTime > Self.adEnd }, "nothing anchored after the ad")

        // A transcript cue 25 s into the reference is 35 s into this listener's audio.
        XCTAssertEqual(try XCTUnwrap(manager.playbackTime(forReferenceTime: 25)), 35, accuracy: 0.5)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 35)), 25, accuracy: 0.5)

        // Highlighting follows content either side of the ad and stops during it,
        // with no ad detection anywhere in the pipeline.
        XCTAssertTrue(manager.isWithinMatchedContent(forPlaybackTime: 8))
        XCTAssertTrue(manager.isWithinMatchedContent(forPlaybackTime: 38))
        XCTAssertFalse(manager.isWithinMatchedContent(forPlaybackTime: Self.adStart + Self.adDuration / 2))
        XCTAssertNil(manager.matchedReferenceTime(forPlaybackTime: Self.adStart + Self.adDuration / 2))
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

    /// Re-opening a transcript for an episode already fingerprinted once should cost
    /// nothing: the mapping is read back off disk and no audio is decoded at all.
    func testCompletedPassPersistsAMappingCacheTheNextRunLoadsInsteadOfDecoding() async throws {
        // The cache is all-or-nothing above `fullCoverageThreshold`, and a pass's
        // last window starts a window's length from the end of the file — so the
        // episode has to be long enough for that shortfall to fall under 5%.
        let duration: Double = 170
        let audioURL = directory.appendingPathComponent("episode.caf")
        // Nothing here is above 1 kHz, so a lower rate costs the matcher nothing and
        // keeps a long episode's decode from dominating the suite's runtime.
        try FingerprintFixtures.writeAudio(seconds: duration, sampleRate: 16000, to: audioURL)
        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.makeReference(forAudioAt: audioURL).write(to: referenceURL)
        let request = Self.request(audio: audioURL, reference: referenceURL, duration: duration)

        let first = FingerprintTimingManager()
        await first.testing.prepare(request: request)
        await first.testing.waitForStream()

        XCTAssertEqual(first.state.analyticsName, "active")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: FingerprintMappingCache.mappingPath(forAudioFilePath: audioURL.path)
        ))

        let second = FingerprintTimingManager()
        await second.testing.prepare(request: request)

        // Active the moment preparation returns. A pass that had to decode would
        // still be `.preparing` here.
        XCTAssertEqual(second.state.analyticsName, "active")
        XCTAssertEqual(
            second.snapshot.playbackToReference.map(\.playbackTime),
            first.snapshot.playbackToReference.map(\.playbackTime)
        )
        XCTAssertEqual(
            second.snapshot.playbackToReference.map(\.referenceTime),
            first.snapshot.playbackToReference.map(\.referenceTime)
        )
    }

    /// Closing the transcript has to leave nothing running and nothing mapped — the
    /// next episode starts from a clean manager.
    func testStopCancelsThePassAndClearsTheMapping() async throws {
        let audioURL = directory.appendingPathComponent("episode.caf")
        try FingerprintFixtures.writeAudio(seconds: Self.episodeDuration, to: audioURL)
        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.makeReference(forAudioAt: audioURL).write(to: referenceURL)

        let manager = FingerprintTimingManager()
        await manager.testing.prepare(request: Self.request(audio: audioURL, reference: referenceURL))
        XCTAssertEqual(manager.state.analyticsName, "preparing")

        manager.stop()

        XCTAssertEqual(manager.state.analyticsName, "idle")
        XCTAssertTrue(manager.snapshot.isEmpty)
        // The pass was cancelled rather than left running: nothing it commits after
        // this point can reach the mapping.
        await manager.testing.waitForStream()
        XCTAssertTrue(manager.snapshot.isEmpty)
        XCTAssertEqual(manager.state.analyticsName, "idle")
    }

    /// An episode whose duration the database doesn't know yet can't be windowed at
    /// all, so preparation stops before it starts decoding.
    func testPreparationIsUnavailableWhenTheEpisodeHasNoDuration() async throws {
        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.referenceWithoutCheckpoints(totalDuration: Self.episodeDuration)
            .write(to: referenceURL)

        let manager = FingerprintTimingManager()
        await manager.testing.prepare(request: Self.request(
            audio: directory.appendingPathComponent("episode.caf"),
            reference: referenceURL,
            duration: 0
        ))

        XCTAssertEqual(manager.state.analyticsName, "unavailable")
    }

    /// A reference that decodes but yields nothing to match against is as good as no
    /// reference at all.
    func testPreparationIsUnavailableWhenTheReferenceHasNoCheckpoints() async throws {
        let referenceURL = directory.appendingPathComponent("episode.ref.fp.json")
        try FingerprintFixtures.referenceWithoutCheckpoints(totalDuration: Self.episodeDuration)
            .write(to: referenceURL)

        let manager = FingerprintTimingManager()
        await manager.testing.prepare(request: Self.request(
            audio: directory.appendingPathComponent("episode.caf"),
            reference: referenceURL
        ))

        XCTAssertEqual(manager.state.analyticsName, "unavailable")
    }

    /// The real entry point's first guard — with the flag off nothing is read,
    /// fetched or decoded.
    func testPrepareForCurrentEpisodeIsUnavailableWhenTheFeatureFlagIsOff() {
        featureFlags.set(.syncedTranscripts, value: false)

        let manager = FingerprintTimingManager()
        manager.prepareForCurrentEpisode()

        XCTAssertEqual(manager.state.analyticsName, "unavailable")
        XCTAssertTrue(manager.snapshot.isEmpty)
    }

    private static func request(
        audio: URL,
        reference: URL,
        duration: Double = episodeDuration
    ) -> FingerprintTimingManager.EpisodeRequest {
        FingerprintTimingManager.EpisodeRequest(
            episodeUuid: "episode-uuid",
            podcastUuid: "podcast-uuid",
            duration: duration,
            audioFileURL: audio,
            isStreaming: false,
            referenceFilePath: reference.path
        )
    }
}
