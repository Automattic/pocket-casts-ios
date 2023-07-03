import XCTest

@testable import podcasts

class WhatsNewtests: XCTestCase {
    /// When upgrading from 7.39 to 7.40 and there's a "What's New"
    /// for 7.40, show it
    func testShowWhatsNew() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.40, image: "", title: "", message: "")],
            previousOpenedVersion: 7.39,
            currentVersion: 7.40
        )

        XCTAssertTrue(whatsNew.showIfNeeded())
    }

    /// When just opening the same version, do nothing
    func testDontShowWhatsNew() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.39, image: "", title: "", message: "")],
            previousOpenedVersion: 7.40,
            currentVersion: 7.40
        )

        XCTAssertFalse(whatsNew.showIfNeeded())
    }

    /// When upgrading from 7.37 to 7.42 and there's a "What's New"
    /// for 7.41, show it
    func testShowWhatsNewEvenIfVersionDontMatch() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.41, image: "", title: "", message: "")],
            previousOpenedVersion: 7.37,
            currentVersion: 7.42
        )

        XCTAssertTrue(whatsNew.showIfNeeded())
    }

    /// When opening the app for the first time, show nothing
    func testDontShowWhenFirstOpening() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.41, image: "", title: "", message: "")],
            previousOpenedVersion: nil,
            currentVersion: 7.41
        )

        XCTAssertFalse(whatsNew.showIfNeeded())
    }
}
