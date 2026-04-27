import XCTest

@testable import podcasts

final class FingerprintMappingCacheTests: XCTestCase {

    typealias Entry = FingerprintTimingManager.TimeMappingEntry

    private var tempDirectory: URL!
    private var audioPath: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        audioPath = tempDirectory.appendingPathComponent("episode.mp3").path
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        audioPath = nil
        try super.tearDownWithError()
    }

    // MARK: - Round-trip

    func testSaveThenLoadRoundTripsEntries() throws {
        let referenceData = Data("ref-bytes-v1".utf8)
        let entries = [
            Entry(playbackTime: 0, referenceTime: 0, score: 0.9),
            Entry(playbackTime: 2, referenceTime: 2.1, score: 0.85),
            Entry(playbackTime: 4, referenceTime: 4.2, score: 0.91),
        ]

        FingerprintMappingCache.save(entries, audioFilePath: audioPath, referenceData: referenceData)

        let loaded = try XCTUnwrap(FingerprintMappingCache.load(
            audioFilePath: audioPath,
            referenceData: referenceData
        ))

        XCTAssertEqual(loaded.count, entries.count)
        for (a, b) in zip(loaded, entries) {
            XCTAssertEqual(a.playbackTime, b.playbackTime, accuracy: 0.0001)
            XCTAssertEqual(a.referenceTime, b.referenceTime, accuracy: 0.0001)
            XCTAssertEqual(a.score, b.score, accuracy: 0.0001)
        }
    }

    // MARK: - Hash invalidation

    func testLoadWithDifferentReferenceDataDiscardsCache() throws {
        let originalReference = Data("ref-bytes-v1".utf8)
        let entries = [Entry(playbackTime: 0, referenceTime: 0, score: 1)]
        FingerprintMappingCache.save(entries, audioFilePath: audioPath, referenceData: originalReference)

        // A new server-side reference (different bytes → different hash) must
        // cause the stale mapping to be discarded — interpolating against the
        // old mapping with the new reference timeline would mis-highlight.
        let newReference = Data("ref-bytes-v2".utf8)
        let loaded = FingerprintMappingCache.load(
            audioFilePath: audioPath,
            referenceData: newReference
        )

        XCTAssertNil(loaded)
    }

    // MARK: - Missing file

    func testLoadFromNonexistentPathReturnsNil() {
        let loaded = FingerprintMappingCache.load(
            audioFilePath: tempDirectory.appendingPathComponent("never-saved.mp3").path,
            referenceData: Data("anything".utf8)
        )
        XCTAssertNil(loaded)
    }

    // MARK: - Empty entries are not persisted

    func testSavingEmptyEntriesDoesNotCreateAFile() {
        FingerprintMappingCache.save(
            [],
            audioFilePath: audioPath,
            referenceData: Data("ref".utf8)
        )

        let cachePath = FingerprintMappingCache.mappingPath(forAudioFilePath: audioPath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cachePath))
    }

    // MARK: - Mapping path derivation

    func testMappingPathSitsNextToAudioWithExpectedExtension() {
        let path = FingerprintMappingCache.mappingPath(forAudioFilePath: "/foo/bar/abc.mp3")
        XCTAssertEqual(path, "/foo/bar/abc.map.fp.json")
    }
}
