import UIKit
import XCTest

@testable import podcasts

/// A Discover cell spans the safe area, and its view controller's view runs under it, getting it as layout margins to inset its content by.
@MainActor
final class ViewControllerContainerContentViewTests: XCTestCase {
    private var window: UIWindow!
    private var parent: UIViewController!

    private var safeArea: UIEdgeInsets { parent.view.safeAreaInsets }

    override func setUp() {
        super.setUp()

        parent = UIViewController()
        parent.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 84)

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        window.rootViewController = parent
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
    }

    override func tearDown() {
        window.isHidden = true
        window = nil
        parent = nil

        super.tearDown()
    }

    func testExtendsTheViewBeyondTheSafeArea() {
        let child = UIViewController()
        layOutCell(with: child)

        let frame = frame(of: child)
        XCTAssertEqual(frame.minX, 0)
        XCTAssertEqual(frame.maxX, parent.view.bounds.width)
    }

    func testHandsTheViewTheSafeAreaItRunsUnderAsLayoutMargins() {
        let child = UIViewController()
        layOutCell(with: child)

        XCTAssertEqual(child.view.layoutMargins, UIEdgeInsets(top: 0, left: safeArea.left, bottom: 0, right: safeArea.right))
    }

    /// Puts the view controller in a view as wide as the collection view, as the section does a cell.
    private func layOutCell(with child: UIViewController) {
        XCTAssertEqual(safeArea.left, 20, "The parent has to be in a window for its safe area to apply")
        XCTAssertEqual(safeArea.right, 84)

        let cell = UIView(frame: CGRect(x: 0, y: 0, width: parent.view.bounds.width, height: 100))
        parent.view.addSubview(cell)

        let configuration = UIViewControllerContentConfiguration(parentViewController: parent, viewController: child)
        let content = configuration.makeContentView()
        content.frame = cell.bounds
        cell.addSubview(content)

        parent.view.layoutIfNeeded()
    }

    private func frame(of child: UIViewController) -> CGRect {
        child.view.convert(child.view.bounds, to: parent.view)
    }
}
