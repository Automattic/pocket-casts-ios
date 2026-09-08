import XCTest

@testable import podcasts

final class WhatsNewVideoCaptionsTests: XCTestCase {
    private let vtt = """
    WEBVTT

    1
    00:00:00.000 --> 00:00:02.500
    Open Up Next

    2
    00:00:03.000 --> 00:00:06.000
    Then sort by release date
    """

    func testTextIsTheCueCoveringThatMoment() throws {
        let captions = try XCTUnwrap(WhatsNewVideoCaptions(webVTT: vtt))

        XCTAssertEqual(captions.text(at: 1), "Open Up Next")
        XCTAssertEqual(captions.text(at: 4), "Then sort by release date")
    }

    func testThereIsNoTextBetweenCues() throws {
        let captions = try XCTUnwrap(WhatsNewVideoCaptions(webVTT: vtt))

        XCTAssertNil(captions.text(at: 2.75))
        XCTAssertNil(captions.text(at: 30))
    }

    /// A player reports an indefinite time before it knows the duration.
    func testAnIndefiniteTimeHasNoText() throws {
        let captions = try XCTUnwrap(WhatsNewVideoCaptions(webVTT: vtt))

        XCTAssertNil(captions.text(at: .nan))
        XCTAssertNil(captions.text(at: .infinity))
    }

    func testCaptionsThatAreNotWebVTTAreIgnored() {
        XCTAssertNil(WhatsNewVideoCaptions(webVTT: "<html><body>Not a caption file</body></html>"))
        XCTAssertNil(WhatsNewVideoCaptions(webVTT: ""))
    }

    func testCaptionsThatAreNotTextAreIgnored() {
        XCTAssertNil(WhatsNewVideoCaptions(data: Data([0xFF, 0xFE, 0xFD])))
    }
}
