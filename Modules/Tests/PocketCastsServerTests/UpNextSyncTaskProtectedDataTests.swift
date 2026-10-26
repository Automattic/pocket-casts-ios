@testable import PocketCastsServer
import XCTest

final class UpNextSyncTaskProtectedDataTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "UpNextSyncTaskProtectedDataTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testSyncProceedsWhenLockedAfterStoredValuesWereReadable() {
        defaults.set("1791558699655", forKey: ServerConstants.UserDefaults.upNextServerLastModified)

        XCTAssertFalse(UpNextSyncTask.shouldSkipSync(isProtectedDataAvailable: false, defaults: defaults))
    }

    func testSyncSkippedWhenLockedAndStoredValuesAreUnreadable() {
        XCTAssertTrue(UpNextSyncTask.shouldSkipSync(isProtectedDataAvailable: false, defaults: defaults))
    }

    func testSyncProceedsWhenProtectedDataAvailable() {
        XCTAssertFalse(UpNextSyncTask.shouldSkipSync(isProtectedDataAvailable: true, defaults: defaults))
    }

    func testSyncProceedsWhenProtectedDataStateUnknown() {
        XCTAssertFalse(UpNextSyncTask.shouldSkipSync(isProtectedDataAvailable: nil, defaults: defaults))
    }
}
