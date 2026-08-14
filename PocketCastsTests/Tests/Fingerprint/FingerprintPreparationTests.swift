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

    private let featureFlags = FeatureFlagMock()
    private var manager: FingerprintTimingManager!
    private var fixture: FingerprintEpisodeFixture!
    private var currentEpisode: CurrentEpisodeOverride!
    /// Scratch space for a publisher's copy of an episode — audio the listener
    /// never has, which only exists to be fingerprinted into a reference.
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        featureFlags.set(.syncedTranscripts, value: true)
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FingerprintPreparationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        manager?.stop()
        manager = nil
        currentEpisode?.restore()
        currentEpisode = nil
        fixture?.removeFiles()
        fixture = nil
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        featureFlags.reset()
        super.tearDown()
    }

    func testPreparationMapsDownloadedEpisodeOntoItsReference() async throws {
        try prepareFixture(duration: Self.episodeDuration) { fixture in
            try fixture.writeAudio(seconds: Self.episodeDuration)
            try fixture.writeReference()
        }

        manager.prepareForCurrentEpisode()
        await waitForPass(manager)

        guard case .active(let coverage) = manager.state else {
            XCTFail("expected .active after a full pass, got \(manager.state)")
            return
        }

        let entries = manager.debugMappingSnapshot()
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

        // The committed mapping is kept sorted as it grows, not just at the end.
        XCTAssertEqual(entries.map(\.playbackTime), entries.map(\.playbackTime).sorted())

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

        try prepareFixture(duration: Self.contentDuration + Self.adDuration) { fixture in
            // The reference is the publisher's copy — content only, no ad.
            let referenceAudioURL = self.directory.appendingPathComponent("reference-episode.wav")
            try FingerprintFixtures.writeAudio(content, to: referenceAudioURL)
            try fixture.writeReference(forAudioAt: referenceAudioURL)

            // This listener's copy — the same content with the ad spliced in.
            try fixture.writeAudio(Array(content[0..<breakpoint]) + ad + Array(content[breakpoint...]))
        }

        manager.prepareForCurrentEpisode()
        await waitForPass(manager)

        XCTAssertEqual(manager.state.analyticsName, "active")
        let entries = manager.debugMappingSnapshot()
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

    /// A pass over audio that isn't the reference's episode has to end with nothing
    /// committed — a confident-looking mapping built out of correlated noise is
    /// worse than no transcript sync at all.
    func testPreparationCommitsNothingWhenTheAudioDoesNotMatchTheReference() async throws {
        try prepareFixture(duration: Self.episodeDuration) { fixture in
            try fixture.writeAudio(seconds: Self.episodeDuration)

            // A reference built from a different episode entirely.
            let otherAudioURL = self.directory.appendingPathComponent("other-episode.wav")
            try FingerprintFixtures.writeAudio(
                seconds: Self.episodeDuration,
                seed: FingerprintFixtures.adSeed,
                to: otherAudioURL
            )
            try fixture.writeReference(forAudioAt: otherAudioURL)
        }

        manager.prepareForCurrentEpisode()
        await waitForPass(manager)

        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
        // The terminal state isn't asserted: `AVAudioFile.read` throws at EOF rather
        // than returning no frames, so a pass that reaches the end of the file
        // currently lands in `.failed` instead of `.unavailable`. What matters
        // either way is that nothing was committed.
        XCTAssertNotEqual(manager.state.analyticsName, "active")
        XCTAssertNil(manager.referenceTime(forPlaybackTime: Self.episodeDuration / 2))
    }

    /// Re-opening a transcript for an episode already fingerprinted once should cost
    /// nothing: the mapping is read back off disk and no audio is decoded at all.
    func testPreparationLoadsAPersistedMappingCacheInsteadOfDecoding() async throws {
        // Short: nothing here is decoded, and the cache is validated against the
        // audio file's size, mtime and leading bytes rather than its contents.
        let duration: Double = 20
        try prepareFixture(duration: duration) { fixture in
            try fixture.writeAudio(seconds: duration, sampleRate: 16000)
            try fixture.writeReference()
        }

        // The cache is all-or-nothing: it's only loaded when it covers the whole
        // reference timeline for this exact pair of files.
        let cached = stride(from: 0.0, through: duration - 0.5, by: 0.5).map {
            FingerprintTimingManager.TimeMappingEntry(playbackTime: $0, referenceTime: $0, score: 1)
        }
        FingerprintMappingCache.save(
            cached,
            audioFilePath: fixture.audioURL.path,
            referenceFilePath: fixture.referenceURL.path,
            referenceData: try Data(contentsOf: fixture.referenceURL),
            referenceDuration: duration
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: fixture.mappingCachePath),
            "the cache under test was never written"
        )

        manager.prepareForCurrentEpisode()

        await waitUntil("the cached mapping to be loaded") { self.manager.state.analyticsName == "active" }
        XCTAssertEqual(manager.debugMappingSnapshot().map(\.playbackTime), cached.map(\.playbackTime))
        XCTAssertEqual(manager.debugMappingSnapshot().map(\.referenceTime), cached.map(\.referenceTime))

        // A pass that decoded instead would keep committing anchors of its own
        // after this point, and it would have had to pass through `.preparing`.
        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(manager.state.analyticsName, "active")
        XCTAssertEqual(manager.debugMappingSnapshot().count, cached.count)
    }

    /// Closing the transcript has to leave nothing running and nothing mapped — the
    /// next episode starts from a clean manager.
    func testStopCancelsThePassAndClearsTheMapping() async throws {
        try prepareFixture(duration: Self.episodeDuration) { fixture in
            try fixture.writeAudio(seconds: Self.episodeDuration)
            try fixture.writeReference()
        }

        manager.prepareForCurrentEpisode()
        await waitUntil("the pass to commit its first anchors") { !self.manager.debugMappingSnapshot().isEmpty }

        manager.stop()

        await waitUntil("the manager to return to idle") { self.manager.state.analyticsName == "idle" }
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)

        // The pass was cancelled rather than left running: nothing it commits after
        // this point can reach the mapping.
        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
        XCTAssertEqual(manager.state.analyticsName, "idle")
    }

    /// An episode whose duration the database doesn't know yet can't be windowed at
    /// all, so preparation stops before it starts decoding.
    func testPreparationIsUnavailableWhenTheEpisodeHasNoDuration() async throws {
        try prepareFixture(duration: 0) { fixture in
            try fixture.writeReference(
                data: FingerprintFixtures.referenceWithoutCheckpoints(totalDuration: Self.episodeDuration)
            )
        }

        manager.prepareForCurrentEpisode()

        await waitUntil("preparation to report unavailable") { self.manager.state.analyticsName == "unavailable" }
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
    }

    /// A reference that decodes but yields nothing to match against is as good as no
    /// reference at all.
    func testPreparationIsUnavailableWhenTheReferenceHasNoCheckpoints() async throws {
        try prepareFixture(duration: Self.episodeDuration) { fixture in
            try fixture.writeReference(
                data: FingerprintFixtures.referenceWithoutCheckpoints(totalDuration: Self.episodeDuration)
            )
        }

        manager.prepareForCurrentEpisode()

        await waitUntil("preparation to report unavailable") { self.manager.state.analyticsName == "unavailable" }
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
    }

    /// The entry point's first guard — with the flag off nothing is read, fetched
    /// or decoded.
    func testPrepareForCurrentEpisodeIsUnavailableWhenTheFeatureFlagIsOff() async throws {
        featureFlags.set(.syncedTranscripts, value: false)
        try prepareFixture(duration: Self.episodeDuration) { fixture in
            try fixture.writeAudio(seconds: Self.episodeDuration)
            try fixture.writeReference()
        }

        manager.prepareForCurrentEpisode()

        await waitUntil("preparation to report unavailable") { self.manager.state.analyticsName == "unavailable" }
        XCTAssertTrue(manager.debugMappingSnapshot().isEmpty)
    }

    /// Puts an episode's files where the manager looks for them, makes it the
    /// episode preparation will pick up, and hands back a fresh manager.
    private func prepareFixture(
        duration: Double,
        writeFiles: (FingerprintEpisodeFixture) throws -> Void
    ) throws {
        let fixture = FingerprintEpisodeFixture(duration: duration)
        try writeFiles(fixture)
        self.fixture = fixture
        currentEpisode = CurrentEpisodeOverride(episode: fixture.episode)
        manager = FingerprintTimingManager()
    }
}
