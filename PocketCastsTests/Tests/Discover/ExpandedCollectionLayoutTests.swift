import UIKit
import XCTest

@testable import podcasts

@MainActor
final class ExpandedCollectionLayoutTests: XCTestCase {
    private let width: CGFloat = 466
    private let sideBarWidth: CGFloat = 84

    private var window: UIWindow!
    private var controller: ExpandedCollectionViewController!

    override func setUp() {
        super.setUp()

        controller = ExpandedCollectionViewController(
            item: DiscoverPreviewData.item(.collectionSummary, title: "Relay", expandedStyle: "network_grid"),
            podcasts: DiscoverPreviewData.podcasts(6)
        )
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: sideBarWidth)

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 678))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
    }

    override func tearDown() {
        window = nil
        controller = nil
        super.tearDown()
    }

    func testGridStaysInsideTheHorizontalSafeArea() throws {
        let collectionView = try XCTUnwrap(controller.collectionView)
        let layout = try XCTUnwrap(collectionView.collectionViewLayout as? UICollectionViewFlowLayout)
        collectionView.layoutIfNeeded()

        let safeArea = collectionView.bounds.inset(by: UIEdgeInsets(top: 0, left: collectionView.safeAreaInsets.left, bottom: 0, right: collectionView.safeAreaInsets.right))
        XCTAssertEqual(safeArea.maxX, width - sideBarWidth)

        let attributes = try (0 ..< 6).map { try XCTUnwrap(layout.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))) }
        for attribute in attributes {
            XCTAssertGreaterThanOrEqual(attribute.frame.minX, safeArea.minX)
            XCTAssertLessThanOrEqual(attribute.frame.maxX, safeArea.maxX)
        }
    }
}
