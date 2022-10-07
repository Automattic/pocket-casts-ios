import XCTest

@testable import podcasts

class AnalyticsPlaybackHelperTests: XCTestCase {
    func testCurrentSourceIsRemovedAfterEventIsTriggered() {
        AnalyticsPlaybackHelper.shared.currentSource = .unknown

        AnalyticsPlaybackHelper.shared.play()

        eventually {
            XCTAssertNil(AnalyticsPlaybackHelper.shared.currentSource)
        }
    }
}
