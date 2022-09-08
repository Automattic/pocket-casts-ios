import XCTest

@testable import podcasts

class AnalyticsPlaybackHelperTests: XCTestCase {
    func testCurrentSourceIsRemovedAfterEventIsTriggered() {
        AnalyticsPlaybackHelper.shared.currentSource = "test"

        AnalyticsPlaybackHelper.shared.play()

        XCTAssertNil(AnalyticsPlaybackHelper.shared.currentSource)
    }
}
