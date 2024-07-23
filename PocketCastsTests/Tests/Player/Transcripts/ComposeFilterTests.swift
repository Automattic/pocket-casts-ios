import XCTest

@testable import podcasts

final class ComposeFilterTests: XCTestCase {

    func testAddEmptySpaceAfterSentence() throws {
        let transcript = """
        This content should get an extra space
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        XCTAssertEqual(filtered, "This content should get an extra space ")
    }

    func testSpeakerX() throws {
        let transcript = """
        Speaker 1: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus imperdiet condimentum ligula quis fringilla. Donec eu ultricies enim. Aenean eu risus leo. Nulla facilisi.
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        let expected = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Phasellus imperdiet condimentum ligula quis fringilla.
        Donec eu ultricies enim.
        Aenean eu risus leo.
        Nulla facilisi.
        """

        XCTAssertEqual(filtered.trim(), expected.trim())
    }

    func testTags() {
        let transcript = """
        <Speaker 1>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus imperdiet condimentum ligula quis fringilla. Donec eu ultricies enim. Aenean eu risus leo. Nulla facilisi.
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        let expected = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Phasellus imperdiet condimentum ligula quis fringilla.
        Donec eu ultricies enim.
        Aenean eu risus leo.
        Nulla facilisi.
        """

        XCTAssertEqual(filtered.trim(), expected.trim())
    }

}
