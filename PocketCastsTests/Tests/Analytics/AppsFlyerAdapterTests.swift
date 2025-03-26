import XCTest

@testable import podcasts

final class AppsFlyerAdapterTests: XCTestCase {

    func testAdapter() throws {
        let attController = AppTrackingTransparencyControllerMock()
        let adapter = AppsFlyerAdapterMock(appTrackingTransparencyProvider: attController)
        adapter.track(name: "test 1", properties: nil)

        XCTAssertNil(adapter.trackedName)
        XCTAssertFalse(adapter.didAuthorize)
        XCTAssertTrue(attController.shouldShowPrompt())

        attController.authState = .authorized

        XCTAssertFalse(attController.shouldShowPrompt())
        XCTAssertTrue(adapter.didAuthorize)
        XCTAssertTrue(attController.userGaveConsent())

        adapter.track(name: "test 2", properties: nil)
        XCTAssertEqual(adapter.trackedName, "test 2")

        attController.authState = .denied

        adapter.track(name: "test 3", properties: nil)
        XCTAssertNil(adapter.trackedName)
    }
}

fileprivate class AppsFlyerAdapterMock: AnalyticsAdapter {
    private(set) var trackedName: String?
    private(set) var didAuthorize = false
    private var appTrackingTransparencyProvider: AppTrackingTransparencyProvider

    func track(name: String, properties: [AnyHashable: Any]?) {
        guard appTrackingTransparencyProvider.userGaveConsent() else {
            trackedName = nil
            return
        }
        trackedName = name
    }

    init(
        appTrackingTransparencyProvider: AppTrackingTransparencyProvider
    ) {
        self.appTrackingTransparencyProvider = appTrackingTransparencyProvider
        setup()
    }

    func setup() {
        appTrackingTransparencyProvider.authorizationStatusUpdated = { [weak self] value in
            self?.didAuthorize = value
        }
    }
}

fileprivate class AppTrackingTransparencyControllerMock: AppTrackingTransparencyProvider {
    enum AuthState {
        case notDetermined
        case denied
        case authorized
    }

    var authState: AuthState = .notDetermined {
        didSet {
            authorizationStatusUpdated?(userGaveConsent())
        }
    }
    var authorizationStatusUpdated: ((Bool) -> Void)?

    func shouldShowPrompt() -> Bool {
        authState == .notDetermined
    }

    func userGaveConsent() -> Bool {
        authState == .authorized
    }

    func userDeniedConsent() -> Bool {
        authState == .denied
    }

    func promptConsentAlert() async -> Bool {
        return false
    }
}
