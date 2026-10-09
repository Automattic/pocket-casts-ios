import UIKit
import XCTest
@testable import podcasts

final class WindowStatusBarAreaTests: XCTestCase {
    func testStatusBarAcrossTheTop() {
        let statusBarFrame = CGRect(x: 0, y: 0, width: 402, height: 54)

        let area = UIWindow.statusBarArea(
            bounds: CGRect(x: 0, y: 0, width: 402, height: 874),
            safeAreaInsets: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
            statusBarFrame: statusBarFrame
        )

        XCTAssertEqual(area, statusBarFrame)
        XCTAssertFalse(area.intersects(CGRect(x: 0, y: 62, width: 402, height: 812)), "A page sheet starts below the status bar")
    }

    func testStatusBarInTrailingVerticalBar() {
        let area = UIWindow.statusBarArea(
            bounds: CGRect(x: 0, y: 0, width: 466, height: 678),
            safeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 84),
            statusBarFrame: CGRect(x: 0, y: 0, width: 466, height: 2)
        )

        XCTAssertEqual(area, CGRect(x: 382, y: 0, width: 84, height: 84))
        XCTAssertTrue(area.intersects(CGRect(x: 8, y: 8, width: 450, height: 670)), "A full-height sheet runs under the status bar")
        XCTAssertFalse(area.intersects(CGRect(x: 8, y: 405, width: 450, height: 265)), "A partial-height sheet stays below it")
    }

    func testStatusBarInLeadingVerticalBar() {
        let area = UIWindow.statusBarArea(
            bounds: CGRect(x: 0, y: 0, width: 466, height: 678),
            safeAreaInsets: UIEdgeInsets(top: 0, left: 84, bottom: 34, right: 0),
            statusBarFrame: CGRect(x: 0, y: 0, width: 466, height: 2)
        )

        XCTAssertEqual(area, CGRect(x: 0, y: 0, width: 84, height: 84))
    }
}
