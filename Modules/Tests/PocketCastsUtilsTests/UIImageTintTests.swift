import UIKit
import XCTest

@testable import PocketCastsUtils

final class UIImageTintTests: XCTestCase {
    func testTintedImageKeepsUpOrientation() throws {
        let image = makeImage(size: CGSize(width: 20, height: 10))

        let tinted = try XCTUnwrap(image.tintedImage(.blue))

        XCTAssertEqual(tinted.imageOrientation, .up)
        XCTAssertEqual(tinted.size, image.size)
    }

    func testTintedImageKeepsMirroredOrientation() throws {
        let image = makeImage(size: CGSize(width: 20, height: 10)).withHorizontallyFlippedOrientation()

        let tinted = try XCTUnwrap(image.tintedImage(.blue))

        XCTAssertEqual(tinted.imageOrientation, .upMirrored)
        XCTAssertEqual(tinted.size, image.size)
    }

    private func makeImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
