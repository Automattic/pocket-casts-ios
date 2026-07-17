import XCTest
@testable import podcasts

/// Covers the sequence `openFullScreenPlayer` relies on to open the player when Play is tapped in
/// the episode details card: UIKit ignores presentations started from a dismissing controller, but
/// a `dismiss(animated:)` on the root can be immediately followed by a `present(_:)` from it.
@MainActor
final class UIViewControllerPresentingTests: XCTestCase {
    private var window: UIWindow!
    private var rootController: UIViewController!

    override func setUp() {
        super.setUp()

        window = UIWindow(frame: UIScreen.main.bounds)
        rootController = UIViewController()
        window.rootViewController = rootController
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        rootController = nil

        super.tearDown()
    }

    func testDismissCanBeImmediatelyFollowedByPresent() {
        let sheet = UIViewController()
        let player = UIViewController()

        present(sheet, from: rootController)

        rootController.dismiss(animated: true)

        let presented = expectation(description: "player presented")
        rootController.present(player, animated: true) {
            presented.fulfill()
        }

        wait(for: [presented], timeout: 5)
        XCTAssertEqual(player.presentingViewController, rootController)
    }

    func testPresentAfterRedundantDismissOfAnAlreadyDismissingController() {
        let sheet = UIViewController()
        let player = UIViewController()

        present(sheet, from: rootController)

        // The episode card dismisses itself when Play is tapped, so the root's dismiss is
        // redundant by the time the player is presented.
        sheet.dismiss(animated: true)
        rootController.dismiss(animated: true)

        let presented = expectation(description: "player presented")
        rootController.present(player, animated: true) {
            presented.fulfill()
        }

        wait(for: [presented], timeout: 5)
        XCTAssertEqual(player.presentingViewController, rootController)
    }

    private func present(_ controller: UIViewController, from presenter: UIViewController) {
        let presented = expectation(description: "presented \(controller)")
        presenter.present(controller, animated: false) {
            presented.fulfill()
        }
        wait(for: [presented], timeout: 5)
    }
}
