@testable import podcasts
import XCTest

final class BackgroundSignOutListenerTests: XCTestCase {
    private var signOutListener: BackgroundSignOutListener!

    func testSignOutAlertShowsWhenNotUserInitiated() {
        let center = NotificationCenter()
        let presentingController = MockPresentingViewController()
        let listener = BackgroundSignOutListener(notificationCenter: center, presentingViewController: presentingController)

        center.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])

        XCTAssertTrue(presentingController.didPresent)
    }

    func testAlertDoesNotShowWhenUserInitiated() {
        let center = NotificationCenter()
        let presentingController = MockPresentingViewController()
        let listener = BackgroundSignOutListener(notificationCenter: center, presentingViewController: presentingController)

        center.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": true])

        XCTAssertFalse(presentingController.didPresent)
    }

    func testSignOutAlertDoesNotShowMoreThanOnce() {
        let center = NotificationCenter()
        let presentingController = MockPresentingViewController()
        _ = BackgroundSignOutListener(notificationCenter: center, presentingViewController: presentingController)

        center.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])
        center.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])

        XCTAssertEqual(presentingController.presentCount, 1)
    }

    func testSignedOutAlertButtonOpensSignIn() throws {
        let center = NotificationCenter()
        let navigationManager = MockNavigationManager()
        let presentingController = MockPresentingViewController()
        let listener = BackgroundSignOutListener(notificationCenter: center,
                                                 presentingViewController: presentingController,
                                                 navigationManager: navigationManager)

        listener.alertAction = MockUIAlertAction.self

        // "Show" the sign out alert
        center.post(name: TestConstants.signOutNotification, object: nil, userInfo: ["user_initiated": false])

        // Trigger the alert action handler
        let alertController = presentingController.presentedController as! UIAlertController
        let action = alertController.actions.first as! MockUIAlertAction
        let handler = try XCTUnwrap(action.mockHandler)

        // Manually trigger the action
        handler(action)

        XCTAssertEqual(NavigationManager.signInPage, navigationManager.navigatedPlace)
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
