import PocketCastsServer
import XCTest

@testable import podcasts

final class NotificationsPermissionsViewModelTests: XCTestCase {
    private var savedOptIn = false
    private var savedNeedsSync = false

    override func setUp() {
        super.setUp()
        savedOptIn = ServerSettings.marketingOptIn()
        savedNeedsSync = ServerSettings.marketingOptInNeedsSyncing()
    }

    override func tearDown() {
        ServerSettings.setMarketingOptIn(savedOptIn)
        if !savedNeedsSync {
            ServerSettings.marketingOptInSynced()
        }
        super.tearDown()
    }

    /// Stores the value the way a sync does, leaving nothing waiting to be sent.
    private func setSyncedOptIn(_ value: Bool) {
        ServerSettings.setMarketingOptIn(value)
        ServerSettings.marketingOptInSynced()
    }

    func testNewAccountStartsTickedAndSavesTheOptIn() {
        setSyncedOptIn(false)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: true)

        XCTAssertTrue(viewModel.newsletterOptIn)

        viewModel.saveNewsletterOptIn()

        XCTAssertTrue(ServerSettings.marketingOptIn())
        XCTAssertTrue(ServerSettings.marketingOptInNeedsSyncing())
    }

    func testOptedOutAccountStartsUntickedAndSavingLeavesItAlone() {
        setSyncedOptIn(false)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: false)

        XCTAssertFalse(viewModel.newsletterOptIn)

        viewModel.saveNewsletterOptIn()

        XCTAssertFalse(ServerSettings.marketingOptIn())
        XCTAssertFalse(ServerSettings.marketingOptInNeedsSyncing())
    }

    func testOptedInAccountStartsTickedAndSavingLeavesItAlone() {
        setSyncedOptIn(true)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: false)

        XCTAssertTrue(viewModel.newsletterOptIn)

        viewModel.saveNewsletterOptIn()

        XCTAssertTrue(ServerSettings.marketingOptIn())
        XCTAssertFalse(ServerSettings.marketingOptInNeedsSyncing())
    }

    func testExistingAccountSavesAChoiceTheUserChanged() {
        setSyncedOptIn(false)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: false)

        viewModel.toggleNewsletterOptIn()
        viewModel.saveNewsletterOptIn()

        XCTAssertTrue(ServerSettings.marketingOptIn())
        XCTAssertTrue(ServerSettings.marketingOptInNeedsSyncing())
    }

    func testSettingThatArrivesWithTheSyncIsShown() {
        setSyncedOptIn(false)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: false)

        setSyncedOptIn(true)
        viewModel.showSyncedNewsletterOptIn()

        XCTAssertTrue(viewModel.newsletterOptIn)
    }

    func testSettingThatArrivesWithTheSyncDoesNotReplaceTheUsersChoice() {
        setSyncedOptIn(true)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: false)

        viewModel.toggleNewsletterOptIn()
        viewModel.showSyncedNewsletterOptIn()

        XCTAssertFalse(viewModel.newsletterOptIn)
    }

    func testNewAccountStaysTickedWhenTheSyncFinishes() {
        setSyncedOptIn(false)
        let viewModel = NotificationsPermissionsViewModel(isNewAccount: true)

        viewModel.showSyncedNewsletterOptIn()

        XCTAssertTrue(viewModel.newsletterOptIn)
    }
}
