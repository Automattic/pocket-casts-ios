import XCTest

@testable import podcasts

final class TranscriptSelectionLogicTests: XCTestCase {

    // MARK: - Helper

    private func makeCues(count: Int, segmentDuration: Double = 5.0) -> (cues: [TranscriptCue], fullText: String) {
        var cues: [TranscriptCue] = []
        var fullText = ""
        for i in 0..<count {
            let text = "Segment \(i). "
            let startTime = Double(i) * segmentDuration
            let endTime = startTime + segmentDuration
            let range = NSRange(location: fullText.count, length: text.count)
            cues.append(TranscriptCue(startTime: startTime, endTime: endTime, characterRange: range))
            fullText += text
        }
        return (cues, fullText)
    }

    // MARK: - selectTranscript

    func testSelectTranscriptCentersOnTimestamp() {
        let (cues, fullText) = makeCues(count: 20)
        // 52.5 falls squarely in cue 10 (50-55), so radius 2 → indices 8..12
        let selection = TranscriptSelectionLogic.selectTranscript(around: 52.5, cues: cues, fullText: fullText, radius: 2)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.startCueIndex, 8)
        XCTAssertEqual(selection?.endCueIndex, 12)
    }

    func testSelectTranscriptClampsAtStart() {
        let (cues, fullText) = makeCues(count: 10)
        let selection = TranscriptSelectionLogic.selectTranscript(around: 2.0, cues: cues, fullText: fullText, radius: 3)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.startCueIndex, 0)
        XCTAssertTrue(selection!.startCueIndex >= 0)
    }

    func testSelectTranscriptClampsAtEnd() {
        let (cues, fullText) = makeCues(count: 10)
        let selection = TranscriptSelectionLogic.selectTranscript(around: 47.0, cues: cues, fullText: fullText, radius: 3)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.endCueIndex, 9)
    }

    func testSelectTranscriptEmptyCues() {
        let selection = TranscriptSelectionLogic.selectTranscript(around: 10.0, cues: [], fullText: "", radius: 3)
        XCTAssertNil(selection)
    }

    func testSelectTranscriptSingleCue() {
        let (cues, fullText) = makeCues(count: 1)
        let selection = TranscriptSelectionLogic.selectTranscript(around: 2.0, cues: cues, fullText: fullText, radius: 3)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.startCueIndex, 0)
        XCTAssertEqual(selection?.endCueIndex, 0)
        XCTAssertEqual(selection?.text, "Segment 0.")
    }

    func testSelectTranscriptUsesNearestCueWhenNoExactMatch() {
        let (cues, fullText) = makeCues(count: 5, segmentDuration: 10.0)
        // Timestamp 7.5 is between cue 0 (0-10) — but let's use 15 which is between 10-20 (cue 1)
        let selection = TranscriptSelectionLogic.selectTranscript(around: 15.0, cues: cues, fullText: fullText, radius: 1)

        XCTAssertNotNil(selection)
        XCTAssertTrue(selection!.startCueIndex <= 1)
        XCTAssertTrue(selection!.endCueIndex >= 1)
    }

    func testSelectTranscriptTimeRangeIsCorrect() {
        let (cues, fullText) = makeCues(count: 10, segmentDuration: 5.0)
        let selection = TranscriptSelectionLogic.selectTranscript(around: 25.0, cues: cues, fullText: fullText, radius: 1)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.startTime, cues[selection!.startCueIndex].startTime)
        XCTAssertEqual(selection?.endTime, cues[selection!.endCueIndex].endTime)
    }

    // MARK: - adjustSelection

    func testAdjustSelectionClampsRange() {
        let (cues, fullText) = makeCues(count: 5)
        let selection = TranscriptSelectionLogic.adjustSelection(startCueIndex: -5, endCueIndex: 100, cues: cues, fullText: fullText)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.startCueIndex, 0)
        XCTAssertEqual(selection?.endCueIndex, 4)
    }

    func testAdjustSelectionSingleCue() {
        let (cues, fullText) = makeCues(count: 5)
        let selection = TranscriptSelectionLogic.adjustSelection(startCueIndex: 2, endCueIndex: 2, cues: cues, fullText: fullText)

        XCTAssertNotNil(selection)
        XCTAssertEqual(selection?.startCueIndex, 2)
        XCTAssertEqual(selection?.endCueIndex, 2)
        XCTAssertEqual(selection?.text, "Segment 2.")
    }

    func testAdjustSelectionInvertedRangeGetsFixed() {
        let (cues, fullText) = makeCues(count: 5)
        let selection = TranscriptSelectionLogic.adjustSelection(startCueIndex: 4, endCueIndex: 1, cues: cues, fullText: fullText)

        XCTAssertNotNil(selection)
        XCTAssertTrue(selection!.startCueIndex <= selection!.endCueIndex)
    }

    func testAdjustSelectionTextIsConcatenated() {
        let (cues, fullText) = makeCues(count: 5)
        let selection = TranscriptSelectionLogic.adjustSelection(startCueIndex: 1, endCueIndex: 3, cues: cues, fullText: fullText)

        XCTAssertNotNil(selection)
        XCTAssertTrue(selection!.text.contains("Segment 1."))
        XCTAssertTrue(selection!.text.contains("Segment 2."))
        XCTAssertTrue(selection!.text.contains("Segment 3."))
    }

    // MARK: - bookmarkCueIndex

    func testBookmarkCueIndexFindsExactMatch() {
        let (cues, _) = makeCues(count: 10)
        let index = TranscriptSelectionLogic.bookmarkCueIndex(for: 12.5, in: cues)
        XCTAssertEqual(index, 2)
    }

    func testBookmarkCueIndexFindsNearestWhenNoExactMatch() {
        let (cues, _) = makeCues(count: 5, segmentDuration: 10.0)
        let index = TranscriptSelectionLogic.bookmarkCueIndex(for: 15.0, in: cues)
        XCTAssertNotNil(index)
    }

    func testBookmarkCueIndexReturnsNilForEmptyCues() {
        let index = TranscriptSelectionLogic.bookmarkCueIndex(for: 10.0, in: [])
        XCTAssertNil(index)
    }

    // MARK: - Heuristic Title

    func testHeuristicTitleTakesFirstFewWords() {
        let text = "one two three four five six seven eight nine ten eleven"
        let title = BookmarkTitleGenerator.heuristicTitle(from: text)
        XCTAssertEqual(title, "one two three four five six seven eight…")
    }

    func testHeuristicTitleKeepsShortTextIntact() {
        let text = "Short title here"
        let title = BookmarkTitleGenerator.heuristicTitle(from: text)
        XCTAssertEqual(title, "Short title here")
    }

    func testHeuristicTitleTruncatesLongText() {
        let longText = String(repeating: "word ", count: 100)
        let title = BookmarkTitleGenerator.heuristicTitle(from: longText)
        XCTAssertTrue(title.count <= Constants.Values.bookmarkMaxTitleLength)
    }

    func testHeuristicTitleFallsBackForEmptyText() {
        let title = BookmarkTitleGenerator.heuristicTitle(from: "")
        XCTAssertEqual(title, L10n.bookmarkDefaultTitle)
    }

    func testHeuristicTitleHandlesNewlines() {
        let text = "Line one\nLine two. Line three."
        let title = BookmarkTitleGenerator.heuristicTitle(from: text)
        XCTAssertFalse(title.contains("\n"))
    }
}
