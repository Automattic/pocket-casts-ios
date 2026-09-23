import XCTest
@testable import PocketCastsDataModel
@testable import podcasts

final class TranscriptFormatTests: XCTestCase {

    private func transcript(type: String) -> Episode.Metadata.Transcript {
        Episode.Metadata.Transcript(url: "https://example.com/transcript", type: type, language: nil)
    }

    func testPlainTextIsASupportedFormat() {
        XCTAssertEqual(transcript(type: "text/plain").transcriptFormat, .textPlain)
    }

    func testMediaTypeParametersAreIgnored() {
        XCTAssertEqual(transcript(type: "text/plain; charset=utf-8").transcriptFormat, .textPlain)
        XCTAssertEqual(transcript(type: "Text/VTT").transcriptFormat, .vtt)
    }

    func testUnknownFormatHasNoMatch() {
        XCTAssertNil(transcript(type: "application/pdf").transcriptFormat)
    }

    func testBestTranscriptPrefersTimedFormatsOverPlainText() {
        let plainText = transcript(type: "text/plain")
        let vtt = transcript(type: "text/vtt")

        XCTAssertEqual(TranscriptFormat.bestTranscript(from: [plainText, vtt])?.transcriptFormat, .vtt)
    }

    func testBestTranscriptUsesPlainTextWhenItIsTheOnlyOne() {
        let plainText = transcript(type: "text/plain")

        XCTAssertEqual(TranscriptFormat.bestTranscript(from: [plainText])?.transcriptFormat, .textPlain)
    }
}
