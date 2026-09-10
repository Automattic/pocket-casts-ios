@testable import podcasts
import UIKit
import XCTest

/// PCIOS-945: multi-select hides the shared tab bar and mini player, so a screen that is
/// still in multi-select when navigation moves elsewhere used to leave them hidden app-wide.
@MainActor
final class EnclosingTabBarHidingTests: XCTestCase {
    private var tabBarController: UITabBarController!
    private var screen: MultiSelectScreenStub!

    override func setUpWithError() throws {
        try super.setUpWithError()

        guard #available(iOS 26, *) else {
            throw XCTSkip("The tab bar is only hidden during multi-select on iOS 26 and later")
        }

        screen = MultiSelectScreenStub()
        tabBarController = UITabBarController()
        tabBarController.viewControllers = [UINavigationController(rootViewController: screen)]
    }

    override func tearDown() {
        screen = nil
        tabBarController = nil

        super.tearDown()
    }

    func testMultiSelectHidesTheTabBar() {
        screen.hidesEnclosingTabBar = true
        screen.updateEnclosingTabBarHidden(isOnScreen: true)

        XCTAssertTrue(isTabBarHidden)
    }

    func testLeavingTheScreenMidMultiSelectRestoresTheTabBar() {
        screen.hidesEnclosingTabBar = true
        screen.updateEnclosingTabBarHidden(isOnScreen: true)

        screen.updateEnclosingTabBarHidden(isOnScreen: false)

        XCTAssertFalse(isTabBarHidden, "Navigating away mid-multi-select must hand the tab bar back")
    }

    func testReturningToTheScreenMidMultiSelectHidesTheTabBarAgain() {
        screen.hidesEnclosingTabBar = true
        screen.updateEnclosingTabBarHidden(isOnScreen: true)
        screen.updateEnclosingTabBarHidden(isOnScreen: false)

        screen.updateEnclosingTabBarHidden(isOnScreen: true)

        XCTAssertTrue(isTabBarHidden)
    }

    func testLeavingTheScreenLeavesTheTabBarAloneWhenItIsNotMultiSelecting() {
        setTabBarHidden(true)

        screen.hidesEnclosingTabBar = false
        screen.updateEnclosingTabBarHidden(isOnScreen: false)

        XCTAssertTrue(isTabBarHidden, "A screen that never hid the tab bar must not show it for another screen")
    }

    func testAppearingLeavesTheTabBarAloneWhenItIsNotMultiSelecting() {
        screen.hidesEnclosingTabBar = false
        screen.updateEnclosingTabBarHidden(isOnScreen: true)

        XCTAssertFalse(isTabBarHidden)
    }

    func testExitingMultiSelectBeforeLeavingKeepsTheTabBarVisible() {
        screen.hidesEnclosingTabBar = true
        screen.updateEnclosingTabBarHidden(isOnScreen: true)

        screen.hidesEnclosingTabBar = false
        screen.setEnclosingTabBarHidden(false, animated: false)
        screen.updateEnclosingTabBarHidden(isOnScreen: false)

        XCTAssertFalse(isTabBarHidden)
    }

    private var isTabBarHidden: Bool {
        guard #available(iOS 26, *) else { return false }

        return tabBarController.isTabBarHidden
    }

    private func setTabBarHidden(_ hidden: Bool) {
        guard #available(iOS 26, *) else { return }

        tabBarController.setTabBarHidden(hidden, animated: false)
    }
}

private final class MultiSelectScreenStub: UIViewController, EnclosingTabBarHiding {
    var hidesEnclosingTabBar = false
}
