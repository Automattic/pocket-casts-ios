import XCTest

@testable import podcasts

final class FingerprintTimingManagerTests: XCTestCase {

    typealias Entry = FingerprintTimingManager.TimeMappingEntry

    // MARK: - Interpolation returns nil for empty entries

    func testInterpolateReturnsNilForEmptyArray() {
        let result = FingerprintTimingManager.interpolate(
            time: 5.0,
            in: [],
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        )
        XCTAssertNil(result)
    }

    // MARK: - Single-entry extrapolation

    func testInterpolateSingleEntryExtrapolatesForward() throws {
        let entries = [Entry(playbackTime: 10.0, referenceTime: 20.0)]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 15.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 25.0, accuracy: 0.001)
    }

    func testInterpolateSingleEntryExtrapolatesBackward() throws {
        let entries = [Entry(playbackTime: 10.0, referenceTime: 20.0)]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 5.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 15.0, accuracy: 0.001)
    }

    // MARK: - Two-entry linear interpolation

    func testInterpolateMidpointBetweenTwoEntries() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 100.0),
            Entry(playbackTime: 10.0, referenceTime: 200.0),
        ]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 5.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 150.0, accuracy: 0.001)
    }

    func testInterpolateQuarterPointBetweenTwoEntries() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 0.0),
            Entry(playbackTime: 100.0, referenceTime: 200.0),
        ]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 25.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 50.0, accuracy: 0.001)
    }

    // MARK: - Multi-entry binary search

    func testInterpolateFindsCorrectSegmentInMultipleEntries() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 0.0),
            Entry(playbackTime: 10.0, referenceTime: 10.0),
            Entry(playbackTime: 20.0, referenceTime: 30.0),
            Entry(playbackTime: 30.0, referenceTime: 60.0),
        ]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 25.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 45.0, accuracy: 0.001)
    }

    // MARK: - Extrapolation beyond range

    func testInterpolateExtrapolatesBeyondLastEntry() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 0.0),
            Entry(playbackTime: 10.0, referenceTime: 20.0),
        ]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 15.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 25.0, accuracy: 0.001)
    }

    func testInterpolateExtrapolatesBeforeFirstEntry() throws {
        let entries = [
            Entry(playbackTime: 10.0, referenceTime: 20.0),
            Entry(playbackTime: 20.0, referenceTime: 40.0),
        ]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 5.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(result, 15.0, accuracy: 0.001)
    }

    // MARK: - Exact boundary match

    func testInterpolateReturnsExactValueAtBoundary() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 100.0),
            Entry(playbackTime: 10.0, referenceTime: 200.0),
        ]

        let resultFirst = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 0.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))
        let resultLast = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 10.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(resultFirst, 100.0, accuracy: 0.001)
        XCTAssertEqual(resultLast, 200.0, accuracy: 0.001)
    }

    // MARK: - Bidirectional lookup

    func testInterpolateWorksForReverseDirection() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 100.0),
            Entry(playbackTime: 10.0, referenceTime: 200.0),
        ]

        let result = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 150.0,
            in: entries,
            keyPath: \.referenceTime,
            valuePath: \.playbackTime
        ))

        XCTAssertEqual(result, 5.0, accuracy: 0.001)
    }

    // MARK: - State enum

    func testStateIdleIsDefault() {
        let manager = FingerprintTimingManager()
        if case .idle = manager.state {
            // expected
        } else {
            XCTFail("Expected .idle, got \(manager.state)")
        }
    }
}
