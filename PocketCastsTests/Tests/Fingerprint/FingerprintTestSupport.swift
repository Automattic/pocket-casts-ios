import Foundation
import XCTest

@testable import PocketCastsDataModel
@testable import podcasts

/// An episode the fingerprint subsystem can actually find.
///
/// `FingerprintTimingManager` takes no file paths: it asks `DownloadManager` where
/// this episode's audio lives and reads its reference fingerprint from the sibling
/// path. So a fixture is an episode plus the files sitting where those lookups
/// point, which is also what a real downloaded episode looks like on disk.
final class FingerprintEpisodeFixture {

    let episode: Episode
    /// Where `DownloadManager` says this episode's audio is, i.e. what the
    /// fingerprint pass will decode.
    let audioURL: URL
    /// The reference fingerprint's path, derived from `audioURL` the same way
    /// `FingerprintTimingManager` derives it.
    let referenceURL: URL

    var mappingCachePath: String {
        FingerprintMappingCache.mappingPath(forAudioFilePath: audioURL.path)
    }

    /// - Parameter duration: the episode's duration as the database knows it.
    ///   Preparation refuses to run without one.
    init(duration: Double) {
        episode = Episode()
        episode.uuid = "fingerprint-tests-\(UUID().uuidString)"
        episode.podcastUuid = "fingerprint-tests-podcast"
        episode.duration = duration
        // Picks the extension `pathForEpisode` builds, which in turn picks the
        // container `AVAudioFile` writes the fixture audio into.
        episode.contentType = "audio/wav"

        audioURL = URL(fileURLWithPath: DownloadManager.shared.pathForEpisode(episode))
        referenceURL = URL(
            fileURLWithPath: (audioURL.path as NSString).deletingPathExtension + ".ref.fp.json"
        )
    }

    @discardableResult
    func writeAudio(
        seconds: Double,
        seed: UInt64 = FingerprintFixtures.contentSeed,
        sampleRate: Double = FingerprintFixtures.defaultSampleRate
    ) throws -> URL {
        try FingerprintFixtures.writeAudio(seconds: seconds, seed: seed, sampleRate: sampleRate, to: audioURL)
        return audioURL
    }

    @discardableResult
    func writeAudio(_ samples: [Float], sampleRate: Double = FingerprintFixtures.defaultSampleRate) throws -> URL {
        try FingerprintFixtures.writeAudio(samples, sampleRate: sampleRate, to: audioURL)
        return audioURL
    }

    /// Builds the reference fingerprint from `url` (this episode's own audio unless
    /// a publisher's copy is passed in) and writes it where the manager looks.
    func writeReference(forAudioAt url: URL? = nil) throws {
        try FingerprintFixtures.makeReference(forAudioAt: url ?? audioURL).write(to: referenceURL)
    }

    func writeReference(data: Data) throws {
        try data.write(to: referenceURL)
    }

    /// Removes everything this fixture put in the shared podcasts directory —
    /// audio, reference, and any mapping cache a pass persisted next to them.
    func removeFiles() {
        for path in [audioURL.path, referenceURL.path, mappingCachePath] {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}

/// Makes an episode the one `PlaybackManager.shared.currentEpisode` hands back, so
/// `prepareForCurrentEpisode()` prepares for it.
///
/// The queue caches the now-playing episode off the shared `DataManager`, so this
/// swaps in one that reports the fixture at the top of Up Next and re-caches. No
/// rows are written, and `restore()` puts the real manager (and its cached
/// episode) back.
final class CurrentEpisodeOverride {

    private let previousDataManager: DataManager

    init(episode: BaseEpisode) {
        previousDataManager = DataManager.sharedManager

        let stub = NowPlayingStubDataManager(dbQueue: previousDataManager.dbQueue)
        stub.nowPlaying = episode
        DataManager.sharedManager = stub
        PlaybackManager.shared.queue.loadPersistedQueue()
    }

    func restore() {
        DataManager.sharedManager = previousDataManager
        PlaybackManager.shared.queue.loadPersistedQueue()
    }
}

private final class NowPlayingStubDataManager: DataManager {
    var nowPlaying: BaseEpisode?

    override func episodeInUpNextAt(index: Int) -> BaseEpisode? {
        index == 0 ? nowPlaying : nil
    }
}

extension XCTestCase {

    /// Polls `condition` on the main actor, which is also where the timing manager
    /// publishes its state — awaiting between checks lets those hops run.
    @MainActor
    func waitUntil(
        _ description: String,
        timeout: TimeInterval = 30,
        pollInterval: TimeInterval = 0.05,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for \(description)", file: file, line: line)
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    /// Waits for a fingerprint pass to run itself out.
    ///
    /// The manager reports no completion — `.active` lands as soon as the first
    /// couple of anchors commit, with most of the file still to decode. So a pass
    /// is finished once it has left `.preparing` and its committed mapping has
    /// stopped growing for `quiet`.
    @MainActor
    func waitForPass(
        _ manager: FingerprintTimingManager,
        quiet: TimeInterval = 1,
        timeout: TimeInterval = 120,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await waitUntil("the pass to start", timeout: timeout, file: file, line: line) {
            manager.state.analyticsName != "idle"
        }

        let deadline = Date().addingTimeInterval(timeout)
        var lastCoverage = -1
        var unchangedSince = Date()
        while Date() < deadline {
            let coverage = manager.debugMappingSnapshot().count
            if coverage != lastCoverage {
                lastCoverage = coverage
                unchangedSince = Date()
            }
            if manager.state.analyticsName != "preparing",
               Date().timeIntervalSince(unchangedSince) >= quiet {
                return
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for the fingerprint pass to finish", file: file, line: line)
    }
}
