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

    func testSeekToDoesntCrashWithNanOrInfinite() {
        let helper = AnalyticsPlaybackHelperMock()

        // Forced Infinity
        helper.seek(from: .infinity, to: .infinity, duration: .infinity)
        XCTAssertNil(helper.lastEvent)

        // Forced NaN check
        helper.seek(from: .nan, to: .nan, duration: .nan)
        XCTAssertNil(helper.lastEvent)

        // Natural NaN check
        helper.seek(from: 0, to: 0, duration: 0)
        XCTAssertNil(helper.lastEvent)
    }

    func testSeekTracksValidValues() {
        let helper = AnalyticsPlaybackHelperMock()

        // 0%
        helper.seek(from: 0, to: 0, duration: 10)
        XCTAssertEqual(helper.lastEvent?.event, .playbackSeek)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_to_percent"] as? Int, 0)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_from_percent"] as? Int, 0)

        // 50% / 100%
        helper.seek(from: 10, to: 5, duration: 10)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_to_percent"] as? Int, 50)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_from_percent"] as? Int, 100)
    }
}

// MARK: - AnalyticsPlaybackHelper Mock

private class AnalyticsPlaybackHelperMock: AnalyticsPlaybackHelper {
    var lastEvent: TrackEvent?

    override func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        lastEvent = .init(event: event, properties: properties)
    }

    struct TrackEvent {
        let event: AnalyticsEvent
        let properties: [String: Any]?
    }
}
