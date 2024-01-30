@testable import podcasts
import XCTest

final class BackgroundSignOutListenerTests: XCTestCase {
    private var signOutListener: BackgroundSignOutListener!
    private var notificationCenter: NotificationCenter!
    private var presentingController: MockPresentingViewController!
    private var navigationManager: MockNavigationManager!

    override func setUp() {
        notificationCenter = NotificationCenter()
        presentingController = MockPresentingViewController()
        navigationManager = MockNavigationManager()

        signOutListener = BackgroundSignOutListener(notificationCenter: notificationCenter,
                                                    navigationManager: navigationManager,
                                                    presentingViewController: self.presentingController)
    }

    func testSignOutAlertShowsWhenNotUserInitiated() {
        notificationCenter.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])

        XCTAssertTrue(presentingController.didPresent)
    }

    func testAlertDoesNotShowWhenUserInitiated() {
        notificationCenter.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": true])
        XCTAssertFalse(presentingController.didPresent)
    }

    func testSignOutAlertDoesNotShowMoreThanOnce() {
        notificationCenter.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])
        notificationCenter.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])

        XCTAssertEqual(presentingController.presentCount, 1)
    }

    func testSignOutAlertActionWillOpenSignIn() {
        signOutListener.showSignIn()

        XCTAssertEqual(NavigationManager.onboardingFlow, navigationManager.navigatedPlace)
    }

    func testSignOutAlertCanShowAgain() {
        // Trigger the initial sign out alert
        notificationCenter.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])
        XCTAssertEqual(presentingController.presentCount, 1)

        // Trigger the dismiss action
        signOutListener.showSignIn()

        // Verify the alert can show again after dismissing the alert
        notificationCenter.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])
        XCTAssertEqual(presentingController.presentCount, 2)
    }

    private enum TestConstants {
        static let signOutNotification = NSNotification.Name("Server.User.WillBeSignedOut")
    }
}

private class MockNavigationManager: NavigationManager {
    var navigatedPlace: String?
    var navigatedData: NSDictionary?

    override func navigateTo(_ place: String, data: NSDictionary?) {
        navigatedPlace = place
        navigatedData = data
    }
}

private class MockPresentingViewController: UIViewController {
    var didPresent = false
    var presentCount = 0
    var presentedController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedController = viewControllerToPresent

        didPresent = true
        presentCount += 1
    }
}
