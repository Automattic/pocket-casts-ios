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
        let snippet = try BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 12).get()

        XCTAssertTrue(snippet.text.hasPrefix("that's the thing about selective admissions."))
        XCTAssertTrue(snippet.text.hasSuffix("floated the lottery idea."))
    }

    func testSnippetFailsAsTooShortWithoutEnoughWords() throws {
        let model = try XCTUnwrap(TranscriptModel.makeModel(from: """
        WEBVTT

        0:00:00.000 --> 0:00:05.000
        Too short to title.
        """, format: .vtt))

        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 2).failureReason, .passageTooShort)
    }

    func testSnippetFailsWhenNothingCoversTheTime() throws {
        let model = try makeModel()

        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 600).failureReason, .noTranscriptAtPosition)
    }

    func testTextSkipsSpeakerNamesAndKeepsLineBreaks() throws {
        let model = try makeModel()
        let fullRange = NSRange(location: 0, length: model.attributedText.length)

        let text = BookmarkTranscriptSnippetExtractor.text(in: fullRange, of: model.attributedText)

        XCTAssertEqual(text, """
        that's the thing about selective admissions.
        The difference between the kid who gets in and the kid who doesn't is often basically noise.
        Right, and that's why some researchers have floated the lottery idea.
        """)
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

    // MARK: - passageRange

    func testPassageRangeRoundTripsACapturedPassageAcrossSpeakerChanges() throws {
        let model = try makeModel()
        let snippet = try BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 12).get()

        let range = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.passageRange(for: snippet.text,
                                                                                  at: snippet.range.location,
                                                                                  in: model.attributedText))

        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.text(in: range, of: model.attributedText), snippet.text)
    }

    func testPassageRangeMatchesAPassageStoredWithoutItsLineBreaks() throws {
        let model = try makeModel()
        let snippet = try BookmarkTranscriptSnippetExtractor.extractSnippet(from: model, at: 12).get()

        // Passages captured by earlier versions were flattened to a single line
        let flattened = snippet.text.split(whereSeparator: \.isWhitespace).joined(separator: " ")

        let range = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.passageRange(for: flattened,
                                                                                  at: snippet.range.location,
                                                                                  in: model.attributedText))

        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.text(in: range, of: model.attributedText), snippet.text)
    }

    func testPassageRangeSearchesForTheTextWhenTheLocationDoesNotLineUp() throws {
        let model = try makeModel()
        let passage = "Right, and that's why some researchers have floated the lottery idea."

        // A location pointing at the start of the transcript, where this passage isn't
        let range = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.passageRange(for: passage, at: 0, in: model.attributedText))

        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.text(in: range, of: model.attributedText), passage)
    }

    func testPassageRangeSearchesForTheTextWithoutALocation() throws {
        let model = try makeModel()
        let passage = "Right, and that's why some researchers have floated the lottery idea."

        let range = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.passageRange(for: passage, at: nil, in: model.attributedText))

        XCTAssertEqual(BookmarkTranscriptSnippetExtractor.text(in: range, of: model.attributedText), passage)
    }

    func testPassageRangeUsesTheLocationToDisambiguateARepeatedPassage() throws {
        let duplicated = """
        WEBVTT

        0:00:00.000 --> 0:00:05.000
        The lottery idea comes up again and again.

        0:00:05.000 --> 0:00:10.000
        Some filler in between to keep the two mentions apart.

        0:00:10.000 --> 0:00:15.000
        The lottery idea comes up again and again.
        """
        let model = try XCTUnwrap(TranscriptModel.makeModel(from: duplicated, format: .vtt))
        let passage = "The lottery idea comes up again and again."

        let string = model.attributedText.string as NSString
        let first = string.range(of: passage).location
        let second = string.range(of: passage, options: .backwards).location
        XCTAssertNotEqual(first, second)

        // The captured location points at the second mention, so that's what's highlighted
        let located = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.passageRange(for: passage, at: second, in: model.attributedText))
        XCTAssertEqual(located.location, second)

        // Without a matching location, the search takes the first mention
        let searched = try XCTUnwrap(BookmarkTranscriptSnippetExtractor.passageRange(for: passage, at: nil, in: model.attributedText))
        XCTAssertEqual(searched.location, first)
    }

    func testPassageRangeIsNilWhenThePassageIsAbsent() throws {
        let model = try makeModel()

        XCTAssertNil(BookmarkTranscriptSnippetExtractor.passageRange(for: "a passage no transcript would ever contain",
                                                                     at: nil,
                                                                     in: model.attributedText))
    }
}

// MARK: - Helpers

private extension Result {
    /// The reason a capture failed, for asserting on which one it was
    var failureReason: Failure? {
        if case .failure(let reason) = self { return reason }
        return nil
    }
}
