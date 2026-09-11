import XCTest
@testable import PocketCastsServer

final class ShowWhatsNewDotSettingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        removeStoredValues()
        addTeardownBlock { [weak self] in
            self?.removeStoredValues()
        }
    }

    func testTheDotIsOnByDefault() {
        XCTAssertTrue(ServerSettings.showWhatsNewDot())
        XCTAssertFalse(ServerSettings.showWhatsNewDotNeedsSyncing())
    }

    func testTurningTheDotOffWaitsToBeSynced() {
        ServerSettings.setShowWhatsNewDot(false)

        XCTAssertFalse(ServerSettings.showWhatsNewDot())
        XCTAssertTrue(ServerSettings.showWhatsNewDotNeedsSyncing())

        ServerSettings.showWhatsNewDotSynced()

        XCTAssertFalse(ServerSettings.showWhatsNewDot())
        XCTAssertFalse(ServerSettings.showWhatsNewDotNeedsSyncing())
    }

    /// The dot on the Profile tab follows the setting wherever it changes, including a sync.
    func testChangingTheSettingIsAnnounced() {
        let changed = expectation(forNotification: ServerNotifications.showWhatsNewDotChanged, object: nil)

        ServerSettings.setShowWhatsNewDot(false)

        wait(for: [changed], timeout: 1)
    }

    /// A sync applies the server's value every time, which shouldn't redraw the dot when nothing changed.
    func testApplyingTheCurrentValueIsNotAnnounced() {
        let changed = expectation(forNotification: ServerNotifications.showWhatsNewDotChanged, object: nil)
        changed.isInverted = true

        ServerSettings.setShowWhatsNewDot(true)

        wait(for: [changed], timeout: 0.1)
    }

    private func removeStoredValues() {
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.showWhatsNewDotKey)
        UserDefaults.standard.removeObject(forKey: ServerConstants.UserDefaults.showWhatsNewDotNeedsSyncKey)
    }
}
