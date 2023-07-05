import XCTest

@testable import podcasts

class WhatsNewtests: XCTestCase {
    /// When upgrading from 7.39 to 7.40 and there's a "What's New"
    /// for 7.40, show it
    func testShowWhatsNew() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.40, image: "", title: "", message: "")],
            previousOpenedVersion: "7.39",
            currentVersion: "7.40"
        )

        XCTAssertNotNil(whatsNew.viewControllerToShow())
    }

    /// When just opening the same version, do nothing
    func testDontShowWhatsNew() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.39, image: "", title: "", message: "")],
            previousOpenedVersion: "7.40",
            currentVersion: "7.40"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    /// When upgrading from 7.37 to 7.42 and there's a "What's New"
    /// for 7.41, show it
    func testShowWhatsNewEvenIfVersionDontMatch() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.41, image: "", title: "", message: "")],
            previousOpenedVersion: "7.37",
            currentVersion: "7.42"
        )

        XCTAssertNotNil(whatsNew.viewControllerToShow())
    }

    /// When opening the app for the first time, show nothing
    func testDontShowWhenFirstOpening() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.41, image: "", title: "", message: "")],
            previousOpenedVersion: nil,
            currentVersion: "7.41"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If the announcement is for a future version, don't show
    func testDontShowWhenFutureVersion() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.50, image: "", title: "", message: "")],
            previousOpenedVersion: "7.41",
            currentVersion: "7.41"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If there's an announcement for the current version but the user
    // already opened it, show nothing
    func testDontShowWhatsNewForTheCurrentOpenedVersion() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.41, image: "", title: "", message: "")],
            previousOpenedVersion: "7.41",
            currentVersion: "7.41"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If there's an announcement for the current hotfix and the user
    // hasn't opened this version yet, show what's new
    func testShowWhatsNewForHotfix() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.42, image: "", title: "", message: "")],
            previousOpenedVersion: "7.41",
            currentVersion: "7.42.1"
        )

        XCTAssertNotNil(whatsNew.viewControllerToShow())
    }

    // If there's an announcement for the current hotfix and the user
    // has opened this version yet, show what's new
    func testDontShowWhatsNewForHotfix() {
        let whatsNew = WhatsNew(
            announcements: [.init(version: 7.42, image: "", title: "", message: "")],
            previousOpenedVersion: "7.42",
            currentVersion: "7.42.1"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }
}

extension String {
    func toDouble() -> Double {
        (self as NSString).doubleValue
    }
}
