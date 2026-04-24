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

    // MARK: - Drift filter

    func testDriftFilterSequentialStreamInsertsAllInOrder() throws {
        let manager = FingerprintTimingManager()
        // Seven sequential candidates (rate 1), well under the 5 s tolerance.
        let stream = (0..<7).map { i in Entry(playbackTime: Double(i) * 2, referenceTime: Double(i) * 2) }

        manager.stubMatches(stream)

        // All seven should be committed in order, queryable across the range.
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 0)), 0, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 12)), 12, accuracy: 0.001)
    }

    func testDriftFilterDropsLoneOutlier() throws {
        let manager = FingerprintTimingManager()
        // Three sequential (bootstrap), one outlier, three more sequential.
        let stream: [Entry] = [
            Entry(playbackTime: 0, referenceTime: 0),
            Entry(playbackTime: 2, referenceTime: 2),
            Entry(playbackTime: 4, referenceTime: 4),
            Entry(playbackTime: 6, referenceTime: 500), // lone outlier
            Entry(playbackTime: 8, referenceTime: 8),   // back on trend
            Entry(playbackTime: 10, referenceTime: 10),
            Entry(playbackTime: 12, referenceTime: 12),
        ]

        manager.stubMatches(stream)

        // The outlier at playback=6 should have been dropped, not interpolated.
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 4)), 4, accuracy: 0.001)
        // A query right where the outlier was should interpolate between 4 and 8 → 6,
        // not land near 500.
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 6)), 6, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 12)), 12, accuracy: 0.001)
    }

    func testDriftFilterConfirmsRealJump() throws {
        let manager = FingerprintTimingManager()
        // Three sequential, then a 90 s transcript-only ad break jump.
        let stream: [Entry] = [
            Entry(playbackTime: 0, referenceTime: 0),
            Entry(playbackTime: 2, referenceTime: 2),
            Entry(playbackTime: 4, referenceTime: 4),
            Entry(playbackTime: 6, referenceTime: 96),  // jump — pending
            Entry(playbackTime: 8, referenceTime: 98),  // confirms the jump
            Entry(playbackTime: 10, referenceTime: 100),
        ]

        manager.stubMatches(stream)

        // Pre-jump region intact.
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 4)), 4, accuracy: 0.001)
        // Post-jump region also committed.
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 8)), 98, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 10)), 100, accuracy: 0.001)
    }

    func testDriftFilterRejectsJumpAroundNoise() throws {
        let manager = FingerprintTimingManager()
        // Three sequential, then four candidates all over the place, none consistent
        // with each other or with the trusted anchor.
        let stream: [Entry] = [
            Entry(playbackTime: 0, referenceTime: 0),
            Entry(playbackTime: 2, referenceTime: 2),
            Entry(playbackTime: 4, referenceTime: 4),
            Entry(playbackTime: 6, referenceTime: 500),
            Entry(playbackTime: 8, referenceTime: 150),
            Entry(playbackTime: 10, referenceTime: 800),
            Entry(playbackTime: 12, referenceTime: 220),
        ]

        manager.stubMatches(stream)

        // The three bootstrap entries are the only things in the mapping; none of
        // the noise lands. Had any of the noise been accepted, queries in that
        // region would snap to the bogus reference value (e.g. 500 / 150 / 800).
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 2)), 2, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 6)), 6, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 10)), 10, accuracy: 0.001)
    }

    func testDriftFilterBootstrapRollsForwardPastEarlyJump() throws {
        let manager = FingerprintTimingManager()
        // First two candidates would form a consistent pair, but the third breaks
        // rate 1. The window rolls forward until a consistent trio arrives.
        let stream: [Entry] = [
            Entry(playbackTime: 0, referenceTime: 0),
            Entry(playbackTime: 2, referenceTime: 2),
            Entry(playbackTime: 4, referenceTime: 400),  // breaks the trio
            Entry(playbackTime: 6, referenceTime: 402),
            Entry(playbackTime: 8, referenceTime: 404),  // now (4, 400) / (6, 402) / (8, 404) form a rate-1 trio
        ]

        manager.stubMatches(stream)

        // The first two candidates (0→0, 2→2) must NOT be in the mapping — if
        // they had been committed, a query at playback=4 would be 3-ish
        // (midway between (2,2) and the next anchor). Instead the trio
        // (4,400)/(6,402)/(8,404) is the only committed region, so
        // playback=4 pins to 400.
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 4)), 400, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 6)), 402, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.referenceTime(forPlaybackTime: 8)), 404, accuracy: 0.001)
    }

    // MARK: - Static interpolate helper: math correctness

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
