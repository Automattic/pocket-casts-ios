import XCTest

@testable import podcasts

class WidgetAnalyticsTests: XCTestCase {
    let userDefaults = UserDefaults(suiteName: "widgetAnalyticsTests")!

    func testSometing() {
        let widgetAnalytics = WidgetAnalytics(
            userDefaults: userDefaults,
            analytics: AnalyticsMock()
        )
    }
}

// MARK: - Mocks

class AnalyticsMock: Analytics {
    override func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {

    }
}
