import XCTest
@testable import podcasts

@MainActor
final class PCViewControllerTests: XCTestCase {
    func testHidingTheEnclosingTabBarKeepsTheNavigationBarFromMinimizing() throws {
        guard #available(iOS 27, *) else { throw XCTSkip("Navigation bar minimization requires iOS 27") }
        let controller = PCViewController()

        controller.setHidesEnclosingTabBar(true, animated: false)
        XCTAssertEqual(controller.navigationItem.navigationBarMinimization.minimizationBehavior, .never)

        controller.setHidesEnclosingTabBar(false, animated: false)
        XCTAssertEqual(controller.navigationItem.navigationBarMinimization.minimizationBehavior, .automatic)
    }
}
