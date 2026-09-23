import PocketCastsUtils
import UIKit
import XCTest

final class UIColorExtensionsTests: XCTestCase {
    func testParsesSupportedHexLengths() throws {
        XCTAssertEqual(UIColor.from(hex: "#F00")?.hexString(), "#FF0000")
        XCTAssertEqual(UIColor.from(hex: "#00FF00")?.hexString(), "#00FF00")

        let withAlpha = try XCTUnwrap(UIColor.from(hex: "#0000FF80"))
        XCTAssertEqual(withAlpha.hexString(), "#0000FF")
        XCTAssertEqual(withAlpha.getRGBA()[3], 128.0 / 255.0, accuracy: 0.001)
    }

    func testReturnsNilForUnusableValues() {
        XCTAssertNil(UIColor.from(hex: ""))
        XCTAssertNil(UIColor.from(hex: "#"))
        XCTAssertNil(UIColor.from(hex: "FF0000"), "a missing # prefix isn't a color")
        XCTAssertNil(UIColor.from(hex: "#FF000"), "5 digits isn't a supported length")
        XCTAssertNil(UIColor.from(hex: "#ZZZZZZ"))
        XCTAssertNil(UIColor.from(hex: "#FFZZZZ"), "a partially scannable value isn't a color")
    }

    func testInitFallsBackToBlack() {
        XCTAssertEqual(UIColor(hex: "").hexString(), "#000000")
        XCTAssertEqual(UIColor(hex: "#00FF00").hexString(), "#00FF00")
    }
}
