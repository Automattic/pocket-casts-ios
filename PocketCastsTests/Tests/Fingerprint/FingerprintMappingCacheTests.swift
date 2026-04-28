import XCTest

@testable import podcasts

final class FingerprintMappingCacheTests: XCTestCase {

    typealias Entry = FingerprintTimingManager.TimeMappingEntry

    private var tempDir: URL!
    private var audioPath: String!
    private var referenceData: Data!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("FingerprintMappingCacheTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let audioURL = tempDir.appendingPathComponent("episode.mp3")
        try Data(repeating: 0xab, count: 1024).write(to: audioURL)
        audioPath = audioURL.path

        referenceData = Data("reference-bytes-v1".utf8)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        audioPath = nil
        referenceData = nil
        try super.tearDownWithError()
    }

    // MARK: - Round-trip

    func testFullCoverageMappingRoundTrips() throws {
        let entries = makeFullCoverageEntries()
        FingerprintMappingCache.save(
            entries,
            audioFilePath: audioPath,
            referenceData: referenceData,
            referenceDuration: 100
        )

        let loaded = try XCTUnwrap(
            FingerprintMappingCache.load(audioFilePath: audioPath, referenceData: referenceData)
        )
        XCTAssertEqual(loaded.entries.count, entries.count)
        XCTAssertEqual(loaded.referenceDuration, 100, accuracy: 0.001)
        for (i, original) in entries.enumerated() {
            XCTAssertEqual(loaded.entries[i].playbackTime, original.playbackTime, accuracy: 0.001)
            XCTAssertEqual(loaded.entries[i].referenceTime, original.referenceTime, accuracy: 0.001)
            XCTAssertEqual(loaded.entries[i].score, original.score, accuracy: 0.0001)
        }
    }

    // MARK: - Validations

    func testCacheIsRejectedWhenReferenceHashChanges() {
        FingerprintMappingCache.save(
            makeFullCoverageEntries(),
            audioFilePath: audioPath,
            referenceData: referenceData,
            referenceDuration: 100
        )

        let differentReference = Data("different-reference".utf8)
        XCTAssertNil(FingerprintMappingCache.load(audioFilePath: audioPath, referenceData: differentReference))
    }

    func testCacheIsRejectedWhenAudioFileSizeChanges() throws {
        FingerprintMappingCache.save(
            makeFullCoverageEntries(),
            audioFilePath: audioPath,
            referenceData: referenceData,
            referenceDuration: 100
        )

        let url = URL(fileURLWithPath: audioPath)
        try Data(repeating: 0xcd, count: 4096).write(to: url)

        XCTAssertNil(FingerprintMappingCache.load(audioFilePath: audioPath, referenceData: referenceData))
    }

    func testPartialCoverageCacheIsNotPersisted() {
        let partial = [
            Entry(playbackTime: 0, referenceTime: 0, score: 0.9),
            Entry(playbackTime: 10, referenceTime: 10, score: 0.9)
        ]
        FingerprintMappingCache.save(
            partial,
            audioFilePath: audioPath,
            referenceData: referenceData,
            referenceDuration: 100
        )

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: FingerprintMappingCache.mappingPath(forAudioFilePath: audioPath))
        )
    }

    func testEmptyEntriesAreNotPersisted() {
        FingerprintMappingCache.save(
            [],
            audioFilePath: audioPath,
            referenceData: referenceData,
            referenceDuration: 100
        )
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: FingerprintMappingCache.mappingPath(forAudioFilePath: audioPath))
        )
    }

    func testMissingCacheLoadsAsNil() {
        XCTAssertNil(FingerprintMappingCache.load(audioFilePath: audioPath, referenceData: referenceData))
    }

    // MARK: - Helpers

    private func makeFullCoverageEntries() -> [Entry] {
        // Reference duration = 100s; last entry at 99s clears fullCoverageThreshold = 0.95.
        return stride(from: 0.0, through: 99.0, by: 1.0).map {
            Entry(playbackTime: $0, referenceTime: $0, score: 0.85)
        }
    }
}
