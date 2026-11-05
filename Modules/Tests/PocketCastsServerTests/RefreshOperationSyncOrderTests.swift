@testable import PocketCastsServer
@testable import PocketCastsUtils
import XCTest

final class RefreshOperationSyncOrderTests: XCTestCase {
    private let featureFlagMock = FeatureFlagMock()
    private let upNextSyncTask = UpNextSyncTask()
    private let syncTask = SyncTask()

    override func tearDown() {
        featureFlagMock.reset()
        super.tearDown()
    }

    func testUpNextSyncsAfterFullSync() {
        featureFlagMock.set(.syncUpNextAfterFullSync, value: true)

        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: true, isUpNextEmpty: true)

        XCTAssertEqual(tasks.map(ObjectIdentifier.init), [ObjectIdentifier(syncTask), ObjectIdentifier(upNextSyncTask)])
    }

    func testUpNextSyncsFirstInIncrementalSync() {
        featureFlagMock.set(.syncUpNextAfterFullSync, value: true)

        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: false, isUpNextEmpty: true)

        XCTAssertEqual(tasks.map(ObjectIdentifier.init), [ObjectIdentifier(upNextSyncTask), ObjectIdentifier(syncTask)])
    }

    func testUpNextSyncsFirstWhenLocalUpNextHasEpisodes() {
        featureFlagMock.set(.syncUpNextAfterFullSync, value: true)

        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: true, isUpNextEmpty: false)

        XCTAssertEqual(tasks.map(ObjectIdentifier.init), [ObjectIdentifier(upNextSyncTask), ObjectIdentifier(syncTask)])
    }

    func testUpNextSyncsFirstWhenFlagIsOff() {
        featureFlagMock.set(.syncUpNextAfterFullSync, value: false)

        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: true, isUpNextEmpty: true)

        XCTAssertEqual(tasks.map(ObjectIdentifier.init), [ObjectIdentifier(upNextSyncTask), ObjectIdentifier(syncTask)])
    }

    func testFullSyncIsPendingUntilServerModifiedDateIsSaved() throws {
        let suiteName = "RefreshOperationSyncOrderTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(SyncTask.isFullSyncPending(defaults: defaults))

        defaults.set("", forKey: ServerConstants.UserDefaults.lastModifiedServerDate)
        XCTAssertTrue(SyncTask.isFullSyncPending(defaults: defaults))

        defaults.set("1791558699655", forKey: ServerConstants.UserDefaults.lastModifiedServerDate)
        XCTAssertFalse(SyncTask.isFullSyncPending(defaults: defaults))
    }
}
