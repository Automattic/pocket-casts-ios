@testable import PocketCastsServer
import XCTest

final class RefreshOperationSyncOrderTests: XCTestCase {
    private let upNextSyncTask = UpNextSyncTask()
    private let syncTask = SyncTask()

    func testUpNextSyncsAfterFullSync() {
        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: true, isUpNextEmpty: true)

        XCTAssertEqual(tasks.map(ObjectIdentifier.init), [ObjectIdentifier(syncTask), ObjectIdentifier(upNextSyncTask)])
    }

    func testUpNextSyncsFirstInIncrementalSync() {
        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: false, isUpNextEmpty: true)

        XCTAssertEqual(tasks.map(ObjectIdentifier.init), [ObjectIdentifier(upNextSyncTask), ObjectIdentifier(syncTask)])
    }

    func testUpNextSyncsFirstWhenLocalUpNextHasEpisodes() {
        let tasks = RefreshOperation.upNextAndSyncTasks(upNextSyncTask: upNextSyncTask, syncTask: syncTask, isFullSyncPending: true, isUpNextEmpty: false)

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
