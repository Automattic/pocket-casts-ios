import UIKit
import XCTest

@testable import podcasts

/// A Discover cell spans the safe area, and its view controller's view is inset by it unless the row insets itself.
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

    func testInsetsTheViewByTheSafeAreaByDefault() {
        let child = UIViewController()
        _ = layOutCell(with: child, extendsBeyondHorizontalSafeArea: false)

        let frame = frame(of: child)
        XCTAssertEqual(frame.minX, safeArea.left)
        XCTAssertEqual(frame.maxX, parent.view.bounds.width - safeArea.right)
    }

    func testExtendsTheViewBeyondTheSafeAreaWhenAsked() {
        let child = UIViewController()
        _ = layOutCell(with: child, extendsBeyondHorizontalSafeArea: true)

        let frame = frame(of: child)
        XCTAssertEqual(frame.minX, 0)
        XCTAssertEqual(frame.maxX, parent.view.bounds.width)
    }

    func testTheExtendedViewSeesTheSafeAreaItRunsUnder() {
        let child = UIViewController()
        _ = layOutCell(with: child, extendsBeyondHorizontalSafeArea: true)

        XCTAssertEqual(child.view.safeAreaInsets.left, safeArea.left)
        XCTAssertEqual(child.view.safeAreaInsets.right, safeArea.right)
    }

    func testMeasuresTheInsetViewAtTheWidthInsideTheSafeArea() {
        let width = parent.view.bounds.width
        let widthInsideSafeArea = width - safeArea.left - safeArea.right

        let inset = layOutCell(with: wrappingViewController(), extendsBeyondHorizontalSafeArea: false)
        let extended = layOutCell(with: wrappingViewController(), extendsBeyondHorizontalSafeArea: true)

        let insetHeight = height(of: inset, fitting: width)
        XCTAssertEqual(insetHeight, height(of: extended, fitting: widthInsideSafeArea))
        XCTAssertNotEqual(insetHeight, height(of: extended, fitting: width), "The text has to wrap differently at the two widths")
    }

    func testOnlyTheRowsThatInsetThemselvesExtendBeyondTheSafeArea() {
        XCTAssertEqual(
            DiscoverCellType.allCases.filter(\.extendsBeyondHorizontalSafeArea),
            [.categoriesSelector, .featuredSummary, .collectionSummary, .networksList]
        )
    }

    /// Puts the view controller in a view as wide as the collection view, as the section does a cell.
    private func layOutCell(with child: UIViewController, extendsBeyondHorizontalSafeArea: Bool) -> UIView & UIContentView {
        XCTAssertEqual(safeArea.left, 20, "The parent has to be in a window for its safe area to apply")
        XCTAssertEqual(safeArea.right, 84)

        let cell = UIView(frame: CGRect(x: 0, y: 0, width: parent.view.bounds.width, height: 100))
        parent.view.addSubview(cell)

        let configuration = UIViewControllerContentConfiguration(
            parentViewController: parent,
            viewController: child,
            extendsBeyondHorizontalSafeArea: extendsBeyondHorizontalSafeArea
        )
        let content = configuration.makeContentView()
        content.frame = cell.bounds
        cell.addSubview(content)

        parent.view.layoutIfNeeded()
        return content
    }

    private func frame(of child: UIViewController) -> CGRect {
        child.view.convert(child.view.bounds, to: parent.view)
    }

    private func height(of content: UIView, fitting width: CGFloat) -> CGFloat {
        content.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func wrappingViewController() -> UIViewController {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = String(repeating: "A podcast row that wraps its text. ", count: 6)
        label.translatesAutoresizingMaskIntoConstraints = false

        let viewController = UIViewController()
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            label.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        return viewController
    }
}
