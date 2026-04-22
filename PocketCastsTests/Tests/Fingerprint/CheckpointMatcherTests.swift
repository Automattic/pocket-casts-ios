import XCTest

@testable import podcasts

final class CheckpointMatcherTests: XCTestCase {

    // MARK: - Identical fingerprints produce a perfect match

    func testIdenticalFingerprintsReturnHighScore() {
        let data = Data([0xAA, 0xBB, 0xCC, 0xDD]).base64EncodedString()
        let checkpoints = (0..<3).map { ReferenceFingerprint.Checkpoint(delta: $0 == 0 ? 0 : 1, data: data) }

        let reference = makeFingerprint(checkpoints: checkpoints)
        let window = makeFingerprint(checkpoints: checkpoints)

        let matches = CheckpointMatcher.findTopMatches(windowFingerprint: window, reference: reference)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.score ?? 0, 1.0, accuracy: 0.001)
        XCTAssertEqual(matches.first?.referenceStartIndex, 0)
    }

    // MARK: - Partial overlap at an offset

    func testWindowMatchesAtCorrectOffset() {
        let sharedData = Data([0xFF, 0xFF]).base64EncodedString()
        let noiseData = Data([0x00, 0x00]).base64EncodedString()

        let refCheckpoints = [
            ReferenceFingerprint.Checkpoint(delta: 0, data: noiseData),
            ReferenceFingerprint.Checkpoint(delta: 1, data: noiseData),
            ReferenceFingerprint.Checkpoint(delta: 1, data: sharedData),
            ReferenceFingerprint.Checkpoint(delta: 1, data: sharedData),
            ReferenceFingerprint.Checkpoint(delta: 1, data: noiseData),
        ]

        let windowCheckpoints = [
            ReferenceFingerprint.Checkpoint(delta: 0, data: sharedData),
            ReferenceFingerprint.Checkpoint(delta: 1, data: sharedData),
        ]

        let reference = makeFingerprint(checkpoints: refCheckpoints)
        let window = makeFingerprint(checkpoints: windowCheckpoints)

        let matches = CheckpointMatcher.findTopMatches(windowFingerprint: window, reference: reference)

        let bestMatch = matches.first
        XCTAssertNotNil(bestMatch)
        XCTAssertEqual(bestMatch?.referenceStartIndex, 2)
        XCTAssertEqual(bestMatch?.score ?? 0, 1.0, accuracy: 0.001)
    }

    // MARK: - Below-threshold matches are filtered

    func testBelowThresholdMatchesAreExcluded() {
        let dataA = Data([0xFF, 0x00]).base64EncodedString()
        let dataB = Data([0x00, 0xFF]).base64EncodedString()

        let refCheckpoints = [ReferenceFingerprint.Checkpoint(delta: 0, data: dataA)]
        let windowCheckpoints = [ReferenceFingerprint.Checkpoint(delta: 0, data: dataB)]

        let reference = makeFingerprint(checkpoints: refCheckpoints)
        let window = makeFingerprint(checkpoints: windowCheckpoints)

        let matches = CheckpointMatcher.findTopMatches(windowFingerprint: window, reference: reference)

        XCTAssertTrue(matches.isEmpty, "Opposite-bit fingerprints should score below threshold")
    }

    // MARK: - Empty inputs

    func testEmptyWindowReturnsNoMatches() {
        let data = Data([0xAA]).base64EncodedString()
        let reference = makeFingerprint(checkpoints: [
            ReferenceFingerprint.Checkpoint(delta: 0, data: data),
        ])
        let window = makeFingerprint(checkpoints: [])

        let matches = CheckpointMatcher.findTopMatches(windowFingerprint: window, reference: reference)
        XCTAssertTrue(matches.isEmpty)
    }

    func testEmptyReferenceReturnsNoMatches() {
        let data = Data([0xAA]).base64EncodedString()
        let reference = makeFingerprint(checkpoints: [])
        let window = makeFingerprint(checkpoints: [
            ReferenceFingerprint.Checkpoint(delta: 0, data: data),
        ])

        let matches = CheckpointMatcher.findTopMatches(windowFingerprint: window, reference: reference)
        XCTAssertTrue(matches.isEmpty)
    }

    // MARK: - maxResults is respected

    func testMaxResultsLimitsOutput() {
        let data = Data([0xFF, 0xFF, 0xFF, 0xFF]).base64EncodedString()
        let checkpoints = (0..<10).map { ReferenceFingerprint.Checkpoint(delta: $0 == 0 ? 0 : 1, data: data) }

        let reference = makeFingerprint(checkpoints: checkpoints)
        let window = makeFingerprint(checkpoints: [checkpoints[0]])

        let matches = CheckpointMatcher.findTopMatches(
            windowFingerprint: window,
            reference: reference,
            maxResults: 3
        )

        XCTAssertLessThanOrEqual(matches.count, 3)
    }

    // MARK: - Results are sorted by score descending

    func testResultsAreSortedByScoreDescending() {
        let highData = Data([0xFF, 0xFF]).base64EncodedString()
        let mediumData = Data([0xFF, 0x0F]).base64EncodedString()

        let refCheckpoints = [
            ReferenceFingerprint.Checkpoint(delta: 0, data: mediumData),
            ReferenceFingerprint.Checkpoint(delta: 1, data: highData),
        ]
        let windowCheckpoints = [
            ReferenceFingerprint.Checkpoint(delta: 0, data: highData),
        ]

        let reference = makeFingerprint(checkpoints: refCheckpoints)
        let window = makeFingerprint(checkpoints: windowCheckpoints)

        let matches = CheckpointMatcher.findTopMatches(windowFingerprint: window, reference: reference)

        guard matches.count >= 2 else { return }
        XCTAssertGreaterThanOrEqual(matches[0].score, matches[1].score)
    }

    // MARK: - Helpers

    private func makeFingerprint(checkpoints: [ReferenceFingerprint.Checkpoint]) -> ReferenceFingerprint {
        ReferenceFingerprint(
            format: ReferenceFingerprint.supportedFormat,
            totalDuration: 60,
            checkpointInterval: 1,
            checkpointDuration: 1,
            topK: 4,
            timestampQuantum: 1000,
            checkpoints: checkpoints
        )
    }
}
