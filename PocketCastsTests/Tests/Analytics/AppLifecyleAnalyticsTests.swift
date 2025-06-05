@testable import podcasts
import XCTest

class AppLifecycleAnalyticsTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var appLifecyleAnalytics: AppLifecycleAnalytics!
    private var analytics: MockAnalytics!

    override func setUp() {
        userDefaults = UserDefaults(suiteName: "AppLifecycleAnalyticsTests")
        userDefaults.removePersistentDomain(forName: "AppLifecycleAnalyticsTests")

        analytics = MockAnalytics()
        appLifecyleAnalytics = AppLifecycleAnalytics(userDefaults: userDefaults, analytics: analytics)
    }

    // MARK: - Application Installed

    func testApplicationInstalledEventFiresWhenLaunched() throws {
        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { event, _ in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationInstalled)
        }

        let applicationInstallState = try XCTUnwrap(checkApplicationInstalledOrUpgraded())

        XCTAssertEqual(applicationInstallState, .installed)

        waitForExpectations(timeout: 1)
    }

    func testApplicationInstalledEventFiresOnlyOnce() throws {
        let expectation = expectation(description: "track method should be triggered only once")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        analytics.didTrack = { event, _ in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationInstalled)
        }

        // First launch
        let applicationInstallState = try XCTUnwrap(checkApplicationInstalledOrUpgraded())

        XCTAssertEqual(applicationInstallState, .installed)

        // Simulated second launch
        checkApplicationInstalledOrUpgraded()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Application Updated

    func testApplicationUpdatedEventFiresWhenLaunched() throws {
        let testVersion = "1.0"
        userDefaults.set(testVersion, forKey: Constants.UserDefaults.lastRunVersion)

        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { event, props in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationUpdated)
            XCTAssertNotNil(props)

            guard let properties = props, let version = properties["previous_version"] as? String else {
                XCTFail("Properties and previous_version should not be nil")
                return
            }

            XCTAssertEqual(testVersion, version)
        }

        let applicationInstallState = try XCTUnwrap(checkApplicationInstalledOrUpgraded())

        XCTAssertEqual(applicationInstallState, .updated)

        waitForExpectations(timeout: 1)
    }

    func testApplicationUpdatedEventIsNotTriggeredForSameVersion() throws {
        userDefaults.set(Settings.appVersion(), forKey: Constants.UserDefaults.lastRunVersion)

        let expectation = expectation(description: "track method should not be triggered")
        expectation.isInverted = true

        analytics.didTrack = { _, _ in
            expectation.fulfill()
            XCTFail("The track method should not be triggered")
        }

        let applicationInstallState = try XCTUnwrap(checkApplicationInstalledOrUpgraded())

        XCTAssertEqual(applicationInstallState, .sameVersion)

        waitForExpectations(timeout: 1)
    }

    func testApplicationUpdatedEventFiresOnlyOnce() {
        userDefaults.set("1.0", forKey: Constants.UserDefaults.lastRunVersion)

        let expectation = expectation(description: "track method should be triggered only once")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        analytics.didTrack = { event, _ in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationUpdated)
        }

        // First launch after initial update, should trigger
        checkApplicationInstalledOrUpgraded()

        // Simulated second launch, should not trigger
        checkApplicationInstalledOrUpgraded()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Last Version Detection

    func testLastVersionIsDetectedCorrectlyV7_20_1() {
        // On first launch of 7.21 there will be no last run version but may be an upgrade key
        userDefaults.set(nil, forKey: Constants.UserDefaults.lastRunVersion)
        userDefaults.set(true, forKey: "v7_20_1_Ghost_Fix")

        let expectedVersion = "7.20.1"
        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { _, props in
            guard let properties = props, let version = properties["previous_version"] as? String else {
                XCTFail("Properties and previous_version should not be nil")
                return
            }

            XCTAssertEqual(expectedVersion, version)
            expectation.fulfill()
        }

        checkApplicationInstalledOrUpgraded()

        waitForExpectations(timeout: 1)
    }

    func testLastVersionIsDetectedCorrectlyV7_11() {
        // On first launch of 7.21 there will be no last run version but may be an upgrade key
        userDefaults.set(nil, forKey: Constants.UserDefaults.lastRunVersion)
        userDefaults.set(true, forKey: "v7_11Run")

        let expectedVersion = "7.11.0"
        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { _, props in
            guard let properties = props, let version = properties["previous_version"] as? String else {
                XCTFail("Properties and previous_version should not be nil")
                return
            }

            XCTAssertEqual(expectedVersion, version)
            expectation.fulfill()
        }

        checkApplicationInstalledOrUpgraded()

        waitForExpectations(timeout: 1)
    }

    func testLastVersionFailedToDetectAndTriggersAppInstalled() {
        userDefaults.set(nil, forKey: Constants.UserDefaults.lastRunVersion)
        userDefaults.set(true, forKey: "SomethingElse")

        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { event, props in
            XCTAssertEqual(event, .applicationInstalled)
            XCTAssertNil(props)

            expectation.fulfill()
        }

        checkApplicationInstalledOrUpgraded()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Application Opened

    func testApplicationOpenedOnAppLaunch() {
        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { event, _ in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationOpened)
        }

        // App is launched
        appLifecyleAnalytics.didBecomeActive()

        waitForExpectations(timeout: 1)
    }

    func testApplicationOpenedNotFiredMoreThanOnce() {
        let expectation = expectation(description: "track method should be triggered only once")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        analytics.didTrack = { event, _ in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationOpened)
        }

        // App is launched
        appLifecyleAnalytics.didBecomeActive()

        // The did become active event is fired again, this should not trigger
        appLifecyleAnalytics.didBecomeActive()

        waitForExpectations(timeout: 1)
    }

    func testApplicationOpenedFiresWhenComingFromBackground() {
        let expectation = expectation(description: "track method should be triggered 3 times")
        expectation.expectedFulfillmentCount = 3

        var expectedEvent: AnalyticsEvent = .applicationOpened
        analytics.didTrack = { event, _ in
            expectation.fulfill()

            XCTAssertEqual(event, expectedEvent)
        }

        // App is launched
        appLifecyleAnalytics.didBecomeActive()

        // App Enters Background
        expectedEvent = .applicationClosed
        appLifecyleAnalytics.didEnterBackground()

        // App becomes active again
        expectedEvent = .applicationOpened
        appLifecyleAnalytics.didBecomeActive()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Application Closed

    func testApplicationClosedFiresOnEnterBackground() {
        let expectation = expectation(description: "track method should be triggered")
        analytics.didTrack = { event, properties in
            expectation.fulfill()

            XCTAssertEqual(event, .applicationClosed)
            XCTAssertEqual(properties?.count, 0)
        }

        // App is backgrounded
        appLifecyleAnalytics.didEnterBackground()

        waitForExpectations(timeout: 1)
    }

    func testApplicationClosedCalculatesTimeInApp() {
        // App is launched
        appLifecyleAnalytics.didBecomeActive()

        // Dismiss the app after 2 seconds
        sleep(2)

        let exp = expectation(description: "track method should be triggered")
        analytics.didTrack = { event, properties in
            exp.fulfill()

            XCTAssertEqual(event, .applicationClosed)

            guard let properties = properties, let time = properties["time_in_app"] as? String else {
                XCTFail("Properties and time_in_app should not be nil")
                return
            }

            XCTAssertEqual("2.0", time)
        }

        appLifecyleAnalytics.didEnterBackground()

        waitForExpectations(timeout: 3)
    }

    @discardableResult
    private func checkApplicationInstalledOrUpgraded() -> AppLifecycleAnalytics.AppInstallState? {
        appLifecyleAnalytics.checkApplicationInstalledOrUpgraded()
    }
}

private class MockAnalytics: Analytics {
    var didTrack: ((_ event: AnalyticsEvent, _ properties: [AnyHashable: Any]?) -> Void)?

    override func track(_ event: AnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        didTrack?(event, properties)
    }
}
