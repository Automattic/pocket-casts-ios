import XCTest

@testable import podcasts

/// Covers the lookup that turns the start of a transcript text selection into the cue whose
/// time the bookmark is created at.
final class TranscriptModelCueLookupTests: XCTestCase {

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

    func testIndexInsideACueReturnsThatCue() throws {
        let model = try makeModel()
        let second = model.cues[1]

        let cue = try XCTUnwrap(model.cue(atCharacterIndex: second.characterRange.location + 3))

        XCTAssertEqual(cue.startTime, second.startTime)
    }

    func testFirstAndLastCharactersOfACueReturnThatCue() throws {
        let model = try makeModel()
        let second = model.cues[1]

        XCTAssertEqual(model.cue(atCharacterIndex: second.characterRange.location)?.startTime, second.startTime)
        XCTAssertEqual(model.cue(atCharacterIndex: second.characterRange.upperBound - 1)?.startTime, second.startTime)
    }

    func testIndexOnASpeakerNameReturnsTheCueItIntroduces() throws {
        let model = try makeModel()
        let third = model.cues[2]
        // A speaker change writes the new name into the gap the previous cue leaves behind
        let speakerIndex = model.cues[1].characterRange.upperBound
        XCTAssertLessThan(speakerIndex, third.characterRange.location)

        let cue = try XCTUnwrap(model.cue(atCharacterIndex: speakerIndex))

        XCTAssertEqual(cue.startTime, third.startTime)
    }

    func testIndexBeforeTheFirstCueReturnsTheFirstCue() throws {
        let model = try makeModel()
        let first = model.cues[0]
        XCTAssertGreaterThan(first.characterRange.location, 0)

        XCTAssertEqual(model.cue(atCharacterIndex: 0)?.startTime, first.startTime)
    }

    func testIndexPastTheLastCueReturnsNil() throws {
        let model = try makeModel()

        XCTAssertNil(model.cue(atCharacterIndex: model.attributedText.length))
    }

    func testCueIsNilWithoutAnyCues() {
        let model = TranscriptModel(attributedText: NSAttributedString(string: "No cues here"), cues: [], type: "", hasJavascript: false)

        XCTAssertNil(model.cue(atCharacterIndex: 0))
    }
}
