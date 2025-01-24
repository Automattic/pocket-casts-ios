import XCTest

@testable import podcasts

class AnalyticsAppThemeProviderTests: XCTestCase {
    private var analytics = MockAnalytics()

    override func setUp() {
        analytics.analyticsAppThemeProvider = MockAnalyticsAppThemeProvider()
    }

    func testThemeProviderProperties() throws {
        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { _, properties in
            expectation.fulfill()

            guard let properties else {
                XCTFail("Properties must not be nil")
                return
            }
            XCTAssertEqual(properties["theme"] as? String, "dark")
            XCTAssertEqual(properties["source"] as? String, "test")
        }
        analytics.track(.settingsAppearanceThemeChanged, properties: ["source": "test"])
        waitForExpectations(timeout: 1)
    }
}

private class MockAnalytics: Analytics {
    var didTrack: ((_ event: AnalyticsEvent, _ properties: [AnyHashable: Any]?) -> Void)?

    override func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        var newProperties = properties ?? [:]
        analyticsAppThemeProvider?.appThemeProperties.forEach { key, value in
            newProperties[key] = value
        }
        didTrack?(event, newProperties)
    }
}

private struct MockAnalyticsAppThemeProvider: AnalyticsAppThemeProviding {
    var appThemeProperties: [String: Any] {
        return ["theme": "dark"]
    }
}
