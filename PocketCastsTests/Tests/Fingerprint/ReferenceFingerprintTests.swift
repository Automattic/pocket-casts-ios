import XCTest

@testable import podcasts

/// The server payload's decoding rules. Everything downstream trusts these
/// timestamps, so a silently mis-scaled one would shift an entire episode's
/// mapping without any stage noticing.
final class ReferenceFingerprintTests: XCTestCase {

    // MARK: - Decoding

    func testDecodesASupportedPayload() throws {
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: Self.payload()))

        XCTAssertEqual(reference.format, ReferenceFingerprint.supportedFormat)
        XCTAssertEqual(reference.totalDuration, 120, accuracy: 0.001)
        XCTAssertEqual(reference.checkpointInterval, 2)
        XCTAssertEqual(reference.checkpointDuration, 8)
        XCTAssertEqual(reference.checkpointDurationSeconds, 8, accuracy: 0.001)
        XCTAssertEqual(reference.checkpoints.count, 3)
    }

    func testRejectsAnUnknownFormat() throws {
        let payload = try Self.payload(overrides: ["format": "fingerprint-compact-v1"])

        XCTAssertNil(ReferenceFingerprint.decode(from: payload))
    }

    func testRejectsPayloadThatIsNotJSON() {
        XCTAssertNil(ReferenceFingerprint.decode(from: Data("not json".utf8)))
    }

    // MARK: - Library checkpoints

    func testTimestampsAccumulateDeltasScaledByTheQuantum() throws {
        // Deltas 0, 2, 2 at one second per unit.
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: Self.payload()))

        XCTAssertEqual(reference.libraryCheckpoints().map(\.timestampSeconds), [0, 2, 4])
    }

    func testQuantumScalesTheTimestampsRatherThanBeingMilliseconds() throws {
        // The same deltas at two seconds per unit land twice as far apart — a
        // /1000 conversion here would collapse them all onto zero.
        let payload = try Self.payload(overrides: ["timestamp_quantum": 2])
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: payload))

        XCTAssertEqual(reference.libraryCheckpoints().map(\.timestampSeconds), [0, 4, 8])
    }

    func testHashesAreDecodedLittleEndian() throws {
        let payload = try Self.payload(checkpoints: [[0, Data([0x01, 0x02, 0x03, 0x04]).base64EncodedString()]])
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: payload))

        XCTAssertEqual(try XCTUnwrap(reference.libraryCheckpoints().first).hashes, [0x0403_0201])
    }

    func testSkipsCheckpointsThatAreNotValidBase64() throws {
        let payload = try Self.payload(checkpoints: [
            [0, "!!!not base64!!!"],
            [2, Data([0x01, 0x00, 0x00, 0x00]).base64EncodedString()]
        ])
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: payload))

        let checkpoints = reference.libraryCheckpoints()
        XCTAssertEqual(checkpoints.count, 1)
        // The skipped checkpoint still advances the accumulated timestamp, so the
        // survivor keeps its own place on the timeline.
        XCTAssertEqual(try XCTUnwrap(checkpoints.first).timestampSeconds, 2)
    }

    func testSkipsCheckpointsWhosePayloadIsNotWholeHashes() throws {
        let payload = try Self.payload(checkpoints: [
            [0, Data([0x01, 0x02, 0x03]).base64EncodedString()],
            [2, Data([0x01, 0x00, 0x00, 0x00]).base64EncodedString()]
        ])
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: payload))

        XCTAssertEqual(reference.libraryCheckpoints().count, 1)
    }

    func testEmptyCheckpointListDecodesToNothingUsable() throws {
        let payload = try Self.payload(checkpoints: [])
        let reference = try XCTUnwrap(ReferenceFingerprint.decode(from: payload))

        XCTAssertTrue(reference.libraryCheckpoints().isEmpty)
    }

    // MARK: - Helpers

    private static func payload(
        checkpoints: [[Any]]? = nil,
        overrides: [String: Any] = [:]
    ) throws -> Data {
        let hashes = Data([0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00]).base64EncodedString()
        var json: [String: Any] = [
            "format": ReferenceFingerprint.supportedFormat,
            "total_duration": 120.0,
            "checkpoint_interval": 2,
            "checkpoint_duration": 8,
            "timestamp_quantum": 1,
            "checkpoints": checkpoints ?? [[0, hashes], [2, hashes], [2, hashes]]
        ]
        json.merge(overrides) { _, new in new }
        return try JSONSerialization.data(withJSONObject: json)
    }
}
