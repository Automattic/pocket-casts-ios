import XCTest

@testable import podcasts

final class BookmarkTranscriptSnippetExtractorTests: XCTestCase {

    private let transcript = """
    WEBVTT

    0:00:00.000 --> 0:00:05.000
    <v Speaker 1>that's the thing about selective admissions.

    0:00:05.000 --> 0:00:10.000
    <v Speaker 1>The difference between the kid who gets in and the kid who doesn't is often basically noise.

    0:00:10.000 --> 0:00:15.000
    <v Speaker 2>Right, and that's why some researchers have floated the lottery idea.
    """

    private func makeModel() throws -> TranscriptModel {
        try XCTUnwrap(TranscriptModel.makeModel(from: transcript, format: .vtt))
    }

    func testSnippetCoversTheCuesAroundTheTime() throws {
        let model = try makeModel()
        let snippet = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 12))

        XCTAssertTrue(snippet.text.hasPrefix("that's the thing about selective admissions."))
        XCTAssertTrue(snippet.text.hasSuffix("floated the lottery idea."))
    }

    func testSnippetIsNilWithoutEnoughWords() throws {
        let model = try XCTUnwrap(TranscriptModel.makeModel(from: """
        WEBVTT

        0:00:00.000 --> 0:00:05.000
        Too short to title.
        """, format: .vtt))

        XCTAssertNil(BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 2))
    }

    func testTextSkipsSpeakerNamesAndCollapsesCueBreaks() throws {
        let model = try makeModel()
        let fullRange = NSRange(location: 0, length: model.attributedText.length)

        let text = BookmarkTranscriptSnippetExtractor.text(in: fullRange, of: model.attributedText)

        XCTAssertFalse(text.contains("Speaker 1"))
        XCTAssertFalse(text.contains("Speaker 2"))
        XCTAssertFalse(text.contains("\n"))
        XCTAssertFalse(text.contains("  "))
    }

    func testSentenceRangeExpandsAnIndexToTheSentenceAroundIt() throws {
        let model = try makeModel()
        let text = model.attributedText.string
        let index = (text as NSString).range(of: "gets in").location
        XCTAssertNotEqual(index, NSNotFound)

        let range = BookmarkTranscriptSnippetExtractor.sentenceRange(containing: index, in: text)
        let sentence = BookmarkTranscriptSnippetExtractor.text(in: range, of: model.attributedText)

        XCTAssertEqual(sentence, "The difference between the kid who gets in and the kid who doesn't is often basically noise.")
    }

    func testSentenceRangeIsEmptyForAnEmptyTranscript() {
        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.sentenceRange(containing: 0, in: ""),
                       NSRange(location: 0, length: 0))
    }
}
