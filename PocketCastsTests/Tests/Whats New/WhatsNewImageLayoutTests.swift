import XCTest

@testable import podcasts

final class WhatsNewImageLayoutTests: XCTestCase {
    private let page = CGSize(width: 362, height: 874)

    func testALandscapeImageFillsTheWidth() {
        let size = WhatsNewImageLayout.size(aspectRatio: 1200 / 750, in: page)

        XCTAssertEqual(size.width, page.width, accuracy: 0.5)
        XCTAssertEqual(size.height, 226, accuracy: 0.5)
    }

    /// A phone screenshot at full width would push everything under it off the page.
    func testAPortraitImageIsHeldToTheHeightTheDesignGivesIt() {
        let size = WhatsNewImageLayout.size(aspectRatio: 222 / 451, in: page)

        XCTAssertLessThan(size.width, page.width)
        XCTAssertEqual(size.height, page.height * 0.52, accuracy: 0.5)
    }

    func testTheAspectRatioIsKept() {
        for aspectRatio in [0.4, 0.75, 1, 1.6, 2.4] as [CGFloat] {
            let size = WhatsNewImageLayout.size(aspectRatio: aspectRatio, in: page)

            XCTAssertEqual(size.width / size.height, aspectRatio, accuracy: 0.01)
        }
    }
}
