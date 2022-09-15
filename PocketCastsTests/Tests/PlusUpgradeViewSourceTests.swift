@testable import podcasts
import XCTest

class PlusUpgradeViewSourceTests: XCTestCase {
    func testPromotionIdIsValid() {
        XCTAssertEqual(PlusUpgradeViewSource.profile.promotionId(), "PROFILE")
        XCTAssertEqual(PlusUpgradeViewSource.appearance.promotionId(), "APPEARANCE")
        XCTAssertEqual(PlusUpgradeViewSource.files.promotionId(), "FILES")
        XCTAssertEqual(PlusUpgradeViewSource.folders.promotionId(), "FOLDERS")
        XCTAssertEqual(PlusUpgradeViewSource.themes.promotionId(), "THEMES")
        XCTAssertEqual(PlusUpgradeViewSource.icons.promotionId(), "ICONS")
        XCTAssertEqual(PlusUpgradeViewSource.watch.promotionId(), "WATCH")
        XCTAssertEqual(PlusUpgradeViewSource.unknown.promotionId(), "UNKNOWN")
    }

    func testPromotionNameReturnsFrom() {
        XCTAssertEqual(PlusUpgradeViewSource.appearance.promotionName(), "Upgrade to Plus from appearance")
        XCTAssertEqual(PlusUpgradeViewSource.profile.promotionName(), "Upgrade to Plus from profile")
    }

    func testPromotionNameReturnsFor() {
        XCTAssertEqual(PlusUpgradeViewSource.files.promotionName(), "Upgrade to Plus for files")
        XCTAssertEqual(PlusUpgradeViewSource.folders.promotionName(), "Upgrade to Plus for folders")
        XCTAssertEqual(PlusUpgradeViewSource.themes.promotionName(), "Upgrade to Plus for themes")
        XCTAssertEqual(PlusUpgradeViewSource.icons.promotionName(), "Upgrade to Plus for icons")
        XCTAssertEqual(PlusUpgradeViewSource.watch.promotionName(), "Upgrade to Plus for watch")
    }

    func testPromotionNameReturnsUnknown() {
        XCTAssertEqual(PlusUpgradeViewSource.unknown.promotionName(), "Unknown")
    }
}
