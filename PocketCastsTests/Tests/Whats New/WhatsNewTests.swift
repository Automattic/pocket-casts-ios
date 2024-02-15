import XCTest
import SwiftUI

@testable import podcasts

class WhatsNewtests: XCTestCase {
    /// When upgrading from 7.39 to 7.40 and there's a "What's New"
    /// for 7.40, show it
    func testShowWhatsNew() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.40")],
            previousOpenedVersion: "7.39",
            currentVersion: "7.40",
            lastWhatsNewShown: nil
        )

        XCTAssertNotNil(whatsNew.viewControllerToShow())
    }

    /// When just opening the same version, do nothing
    func testDontShowWhatsNew() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.39")],
            previousOpenedVersion: "7.40",
            currentVersion: "7.40"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    /// When upgrading from 7.37 to 7.42 and there's a "What's New"
    /// for 7.41, show it
    func testShowWhatsNewEvenIfVersionDontMatch() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.41")],
            previousOpenedVersion: "7.37",
            currentVersion: "7.42",
            lastWhatsNewShown: nil
        )

        XCTAssertNotNil(whatsNew.viewControllerToShow())
    }

    /// When opening the app for the first time, show nothing
    func testDontShowWhenFirstOpening() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.41")],
            previousOpenedVersion: nil,
            currentVersion: "7.41"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If the announcement is for a future version, don't show
    func testDontShowWhenFutureVersion() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.50")],
            previousOpenedVersion: "7.41",
            currentVersion: "7.41"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If there's an announcement for the current version but the user
    // already opened it, show nothing
    func testDontShowWhatsNewForTheCurrentOpenedVersion() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.41")],
            previousOpenedVersion: "7.41",
            currentVersion: "7.41"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If there's an announcement for the current hotfix and the user
    // hasn't opened this version yet, show what's new
    func testShowWhatsNewForHotfix() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.42")],
            previousOpenedVersion: "7.41",
            currentVersion: "7.42.1",
            lastWhatsNewShown: "7.40"
        )

        XCTAssertNotNil(whatsNew.viewControllerToShow())
    }

    // If there's an announcement for the current hotfix and the user
    // has opened this version yet, show what's new
    func testDontShowWhatsNewForHotfix() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.42")],
            previousOpenedVersion: "7.42",
            currentVersion: "7.42.1"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If the current What's New was shown, never show it again
    // In theory, this setup should never happen, but we have
    // reports of the popup appearing for every new beta
    func testDontShowWhatsNewForSameBeta() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.43")],
            previousOpenedVersion: "7.42.0.0",
            currentVersion: "7.44.0.0",
            lastWhatsNewShown: "7.43"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // Don't show any announcements that are disabled even if the other conditions are true
    func testDontShowDisabledAnnouncements() {
        let whatsNew = WhatsNew(
            announcements: [announcement(version: "7.40", isEnabled: false)],
            previousOpenedVersion: "7.39",
            currentVersion: "7.40"
        )

        XCTAssertNil(whatsNew.viewControllerToShow())
    }

    // If there are multiple announcements in the list, we should only show the last one
    func testShowOnlyTheLastAnnouncement() {
        let lastAnnouncement = announcement(version: "7.12")

        let whatsNew = WhatsNew(
            announcements: [
                announcement(version: "7.10"),
                announcement(version: "7.11"),
                lastAnnouncement
            ],
            previousOpenedVersion: "7.00",
            currentVersion: "7.40",
            lastWhatsNewShown: nil
        )

        XCTAssertEqual(whatsNew.visibleAnnouncement?.version, lastAnnouncement.version)
    }

    // Do not show an announcement that has been shown before
    func testDontShowAnAnnouncementTwice() {
        let lastAnnouncement = announcement(version: "7.12")

        let whatsNew = WhatsNew(
            announcements: [
                announcement(version: "7.10"),
                announcement(version: "7.40"),
                lastAnnouncement
            ],
            previousOpenedVersion: "7.00",
            currentVersion: "7.40",
            lastWhatsNewShown: "7.40"
        )

        XCTAssertNil(whatsNew.visibleAnnouncement)
    }

    private func announcement(version: String, isEnabled: Bool = true) -> WhatsNew.Announcement {
        return .init(version: version, header: AnyView(EmptyView()), title: "", message: "", buttonTitle: "", action: {}, isEnabled: isEnabled)
    }
}

extension String {
    func toDouble() -> Double {
        (self as NSString).doubleValue
    }
}
