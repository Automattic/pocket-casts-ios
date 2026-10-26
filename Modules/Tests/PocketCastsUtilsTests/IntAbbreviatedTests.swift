@testable import PocketCastsUtils
import XCTest

class IntAbbreviatedTests: XCTestCase {
    func testEnglishUsesDecimalPoint() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(95_400.abbreviated(locale: locale), "95.4K")
        XCTAssertEqual(1_234_567.abbreviated(locale: locale), "1.2M")
        XCTAssertEqual(999.abbreviated(locale: locale), "999")
    }

    func testGermanUsesDecimalComma() {
        let locale = Locale(identifier: "de_DE")
        XCTAssertEqual(95_400.abbreviated(locale: locale), "95,4K")
        XCTAssertEqual(1_234_567.abbreviated(locale: locale), "1,2M")
    }
}
