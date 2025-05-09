import XCTest

@testable import podcasts

final class AppsFlyerAdapterTests: XCTestCase {

    func testAdapter() throws {
        let attController = AppTrackingTransparencyControllerMock()
        let adapter = AppsFlyerAdapterMock(appTrackingTransparencyProvider: attController)
        adapter.track(name: "test_1", properties: nil)

        XCTAssertNil(adapter.trackedName)
        XCTAssertFalse(adapter.didAuthorize)
        XCTAssertTrue(attController.shouldShowPrompt())

        attController.authState = .authorized

        XCTAssertFalse(attController.shouldShowPrompt())
        XCTAssertTrue(adapter.didAuthorize)
        XCTAssertTrue(attController.userGaveConsent())

        adapter.track(name: "test_2", properties: nil)
        XCTAssertEqual(adapter.trackedName, "test_2")

        attController.authState = .denied

        adapter.track(name: "test_3", properties: nil)
        XCTAssertNil(adapter.trackedName)

        adapter.track(name: "non_supported_event", properties: nil)
        XCTAssertNil(adapter.trackedName)
    }
}

struct AppsFlyerDataProviderMock {
    let supportedEvents: Set<String> = [
        "test_1",
        "test_2",
        "test_3"
    ]
}

fileprivate class AppsFlyerAdapterMock: AnalyticsAdapter {
    private(set) var trackedName: String?
    private(set) var didAuthorize = false
    private var appTrackingTransparencyProvider: AppTrackingTransparencyProvider
    private let dataProvider: AppsFlyerDataProviderMock

    func track(name: String, properties: [AnyHashable: Any]?) {
        guard
            appTrackingTransparencyProvider.userGaveConsent(),
            dataProvider.supportedEvents.contains(name)
        else {
            trackedName = nil
            return
        }
        trackedName = name
    }

    init(
        dataProvider: AppsFlyerDataProviderMock = AppsFlyerDataProviderMock(),
        appTrackingTransparencyProvider: AppTrackingTransparencyProvider
    ) {
        self.dataProvider = dataProvider
        self.appTrackingTransparencyProvider = appTrackingTransparencyProvider
        setup()
    }

    func setup() {
        appTrackingTransparencyProvider.authorizationStatusUpdated = { [weak self] (value, _) in
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
            authorizationStatusUpdated?(userGaveConsent(), "")
        }
    }
    var authorizationStatusUpdated: ((Bool, String) -> Void)?

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
