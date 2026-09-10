@testable import podcasts
import UIKit
import XCTest

/// PCIOS-945: covers the real screens, not just the mechanism, so a screen that starts
/// hiding the tab bar can't forget to hand it back when it goes off-screen.
@MainActor
final class MultiSelectScreenAppearanceTests: XCTestCase {
    private var tabBarController: UITabBarController!

    override func setUpWithError() throws {
        try super.setUpWithError()

        guard #available(iOS 26, *) else {
            throw XCTSkip("The tab bar is only hidden during multi-select on iOS 26 and later")
        }

        tabBarController = UITabBarController()
    }

    override func tearDown() {
        tabBarController = nil

        super.tearDown()
    }

    func testStarredRestoresTheTabBarWhenItGoesOffScreen() {
        let starred = StarredViewController()
        show(starred)
        starred.isMultiSelectEnabled = true
        XCTAssertTrue(isTabBarHidden)

        starred.beginAppearanceTransition(false, animated: false)
        starred.endAppearanceTransition()

        XCTAssertFalse(isTabBarHidden)
    }

    func testStarredHidesTheTabBarAgainWhenItComesBack() {
        let starred = StarredViewController()
        show(starred)
        starred.isMultiSelectEnabled = true
        starred.beginAppearanceTransition(false, animated: false)
        starred.endAppearanceTransition()

        starred.beginAppearanceTransition(true, animated: false)
        starred.endAppearanceTransition()

        XCTAssertTrue(isTabBarHidden)
    }

    func testStarredLeavesTheTabBarAloneWhenItIsNotMultiSelecting() {
        let starred = StarredViewController()
        show(starred)

        starred.beginAppearanceTransition(false, animated: false)
        starred.endAppearanceTransition()

        XCTAssertFalse(isTabBarHidden)
    }

    private func show(_ viewController: UIViewController) {
        tabBarController.viewControllers = [UINavigationController(rootViewController: viewController)]
        viewController.loadViewIfNeeded()
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
    }

    private var isTabBarHidden: Bool {
        guard #available(iOS 26, *) else { return false }

        return tabBarController.isTabBarHidden
    }
}
