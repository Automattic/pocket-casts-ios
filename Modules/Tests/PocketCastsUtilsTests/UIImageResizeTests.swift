import UIKit
import XCTest

@testable import PocketCastsUtils

final class UIImageResizeTests: XCTestCase {
    func testResizeProportionallyScalesToFit() {
        let image = makeImage(size: CGSize(width: 200, height: 100))

        let resized = image.resizeProportionally(to: CGSize(width: 50, height: 50))

        XCTAssertEqual(resized.size, CGSize(width: 50, height: 25))
    }

    func testResizeProportionallyReturnsSameImageWhenSourceHasZeroSize() {
        let image = UIImage()

        let resized = image.resizeProportionally(to: CGSize(width: 50, height: 50))

        XCTAssertTrue(resized === image)
    }

    func testResizedReturnsNilForInvalidSize() {
        let image = makeImage(size: CGSize(width: 10, height: 10))

        XCTAssertNil(image.resized(to: CGSize(width: CGFloat.nan, height: CGFloat.nan)))
        XCTAssertNil(image.resized(to: .zero))
    }

    private func makeImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
