import XCTest

@testable import podcasts

final class FingerprintTimingManagerTests: XCTestCase {

    typealias Entry = FingerprintTimingManager.TimeMappingEntry

    // MARK: - Public query API: empty manager

    func testEmptyManagerReturnsNilForBothDirections() {
        let manager = FingerprintTimingManager()

        XCTAssertNil(manager.referenceTime(forPlaybackTime: 0))
        XCTAssertNil(manager.referenceTime(forPlaybackTime: 100))
        XCTAssertNil(manager.playbackTime(forReferenceTime: 50))
    }

    // MARK: - Public query API: single entry extrapolates in both directions

    func testSingleMappingQueriesExtrapolateForwardAndBackward() throws {
        let manager = FingerprintTimingManager()
        manager.insert(mapping: Entry(playbackTime: 10, referenceTime: 20))

        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 10)), 20, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 15)), 25, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 5)), 15, accuracy: 0.001)
    }

    // MARK: - Public query API: interpolation between two entries

    func testReferenceTimeInterpolatesBetweenTwoEntries() throws {
        let manager = FingerprintTimingManager()
        manager.insert(mapping: Entry(playbackTime: 0, referenceTime: 100))
        manager.insert(mapping: Entry(playbackTime: 10, referenceTime: 200))

        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 5)), 150, accuracy: 0.001)
    }

    // MARK: - Public query API: bidirectional consistency

    func testPlaybackAndReferenceQueriesRoundTrip() throws {
        let manager = FingerprintTimingManager()
        manager.insert(mapping: Entry(playbackTime: 0, referenceTime: 0))
        manager.insert(mapping: Entry(playbackTime: 10, referenceTime: 25))

        let refAtMid = try XCTUnwrap(manager.referenceTime(forPlaybackTime: 5))
        XCTAssertEqual(refAtMid, 12.5, accuracy: 0.001)

        let playbackBack = try XCTUnwrap(manager.playbackTime(forReferenceTime: refAtMid))
        XCTAssertEqual(playbackBack, 5, accuracy: 0.001)
    }

    // MARK: - Sorted insertion invariant under out-of-order inputs

    func testOutOfOrderInsertsStillInterpolateCorrectly() throws {
        let manager = FingerprintTimingManager()

        // Insert in reverse-ish order; the manager should maintain sorted state internally.
        manager.insert(mapping: Entry(playbackTime: 30, referenceTime: 300))
        manager.insert(mapping: Entry(playbackTime: 0, referenceTime: 0))
        manager.insert(mapping: Entry(playbackTime: 20, referenceTime: 200))
        manager.insert(mapping: Entry(playbackTime: 10, referenceTime: 100))

        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 5)), 50, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 15)), 150, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 25)), 250, accuracy: 0.001)
    }

    // MARK: - Reverse-direction array is sorted on reference key, not playback key

    func testReverseLookupUsesReferenceOrderingNotPlaybackOrdering() throws {
        let manager = FingerprintTimingManager()

        // Playback ascending, reference descending — a case where a single shared
        // array sorted only by playback would give the wrong result for reverse lookup.
        manager.insert(mapping: Entry(playbackTime: 0, referenceTime: 300))
        manager.insert(mapping: Entry(playbackTime: 10, referenceTime: 200))
        manager.insert(mapping: Entry(playbackTime: 20, referenceTime: 100))

        // Reference→playback sorted: [(20,100),(10,200),(0,300)]. Querying ref=150
        // sits halfway between the first two entries → playback = midpoint(20, 10) = 15.
        XCTAssertEqual(try XCTUnwrap(manager.playbackTime(forReferenceTime: 150)), 15, accuracy: 0.001)
    }

    // MARK: - Static interpolate helper: math correctness

    func testInterpolateReturnsNilForEmptyArray() {
        let result = FingerprintTimingManager.interpolate(
            time: 5.0,
            in: [],
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        )
        XCTAssertNil(result)
    }

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

    func testInterpolateFindsCorrectSegmentWithBinarySearch() throws {
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

    func testInterpolateReturnsExactValueAtBoundary() throws {
        let entries = [
            Entry(playbackTime: 0.0, referenceTime: 100.0),
            Entry(playbackTime: 10.0, referenceTime: 200.0),
        ]

        let first = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 0.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))
        let last = try XCTUnwrap(FingerprintTimingManager.interpolate(
            time: 10.0,
            in: entries,
            keyPath: \.playbackTime,
            valuePath: \.referenceTime
        ))

        XCTAssertEqual(first, 100.0, accuracy: 0.001)
        XCTAssertEqual(last, 200.0, accuracy: 0.001)
    }
}
