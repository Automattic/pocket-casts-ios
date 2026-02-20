@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import GRDB
import XCTest

/// Tests for UpNextSyncTask, specifically the login sync bug fix.
///
/// Bug: During login sync, pending Up Next changes (especially replace actions) persist
/// because `clearSyncedData(latestActionTime: 0)` doesn't delete any changes with positive timestamps.
///
/// Fix: When `clearPendingUpNextChangesOnLogin` feature flag is enabled, use `Int64.max`
/// instead of `latestActionTime` during login sync to clear all stale pending changes.
final class UpNextSyncTaskTests: XCTestCase {
    private var originalDataManager: DataManager!
    private var dataManager: DataManager!
    private var originalSyncReason: SyncManager.SyncingReason?
    private let featureFlagMock = FeatureFlagMock()

    override func setUp() {
        super.setUp()
        originalDataManager = DataManager.sharedManager
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try! DatabasePool(path: NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite"))))
        DataManager.sharedManager = dataManager
        originalSyncReason = SyncManager.syncReason
    }

    override func tearDown() {
        featureFlagMock.reset()
        SyncManager.syncReason = originalSyncReason
        DataManager.sharedManager = originalDataManager
        dataManager = nil
        originalDataManager = nil
        super.tearDown()
    }

    // MARK: - Login Sync Bug Regression Tests

    /// Test that verifies the bug: without the fix, stale replace actions persist through login sync.
    ///
    /// This test FAILS when the fix is NOT applied (feature flag enabled but fix code missing).
    /// This test PASSES when the fix IS applied (feature flag enabled and fix code present).
    func testLoginSyncClearsPendingReplaceAction_WithFixEnabled() throws {
        // Enable the fix
        featureFlagMock.set(.clearPendingUpNextChangesOnLogin, value: true)

        // Create a stale empty replace action (simulates device clearing queue while offline)
        dataManager.saveReplace(episodeList: [])

        // Verify replace action exists
        XCTAssertNotNil(dataManager.findReplaceAction(), "Replace action should exist before sync")

        // Set sync reason to login
        SyncManager.syncReason = .login

        // Create mock server response with some episodes
        let serverResponse = createMockUpNextResponse(episodeUUIDs: ["server-episode-1", "server-episode-2"])

        // Process the server response (this calls clearSyncedData internally)
        let syncTask = UpNextSyncTask()
        syncTask.process(serverData: serverResponse, latestActionTime: 0)

        // With the fix enabled, the stale replace action should be cleared
        let replaceActionAfterSync = dataManager.findReplaceAction()
        XCTAssertNil(replaceActionAfterSync, "Stale replace action should be cleared during login sync when fix is enabled")
    }

    /// Test that verifies the bug exists when fix is disabled.
    ///
    /// This test documents the buggy behavior - the replace action persists.
    func testLoginSyncDoesNotClearPendingReplaceAction_WithFixDisabled() throws {
        // Disable the fix (default behavior, demonstrates the bug)
        featureFlagMock.set(.clearPendingUpNextChangesOnLogin, value: false)

        // Create a stale empty replace action
        dataManager.saveReplace(episodeList: [])

        // Verify replace action exists
        let replaceActionBefore = dataManager.findReplaceAction()
        XCTAssertNotNil(replaceActionBefore, "Replace action should exist before sync")

        // Set sync reason to login
        SyncManager.syncReason = .login

        // Create mock server response
        let serverResponse = createMockUpNextResponse(episodeUUIDs: ["server-episode-1"])

        // Process the server response
        let syncTask = UpNextSyncTask()
        syncTask.process(serverData: serverResponse, latestActionTime: 0)

        // BUG: Without the fix, the stale replace action persists
        let replaceActionAfterSync = dataManager.findReplaceAction()
        XCTAssertNotNil(replaceActionAfterSync, "BUG: Replace action persists through login sync when fix is disabled")
    }

    /// Test that non-login syncs still work correctly (changes are cleared based on latestActionTime).
    func testNonLoginSyncClearsChangesBasedOnLatestActionTime() throws {
        // This test verifies we didn't break normal sync behavior

        // Create a replace action
        dataManager.saveReplace(episodeList: ["episode-1"])

        let replaceAction = dataManager.findReplaceAction()
        XCTAssertNotNil(replaceAction, "Replace action should exist")
        let actionTime = replaceAction!.utcTime

        // Set sync reason to something other than login
        SyncManager.syncReason = .replace

        // Create mock server response
        let serverResponse = createMockUpNextResponse(episodeUUIDs: ["episode-1"])

        // Process with latestActionTime matching the replace action's time
        let syncTask = UpNextSyncTask()
        syncTask.process(serverData: serverResponse, latestActionTime: actionTime)

        // The replace action should be cleared because latestActionTime >= its utcTime
        let replaceActionAfterSync = dataManager.findReplaceAction()
        XCTAssertNil(replaceActionAfterSync, "Replace action should be cleared during normal sync")
    }

    // MARK: - Helpers

    private func createMockUpNextResponse(episodeUUIDs: [String]) -> Data {
        var response = Api_UpNextResponse()
        response.serverModified = Int64(Date().timeIntervalSince1970 * 1000)

        for uuid in episodeUUIDs {
            var episode = Api_UpNextResponse.EpisodeResponse()
            episode.uuid = uuid
            episode.title = "Test Episode \(uuid)"
            episode.podcast = "test-podcast"
            episode.url = "https://example.com/\(uuid).mp3"
            response.episodes.append(episode)
        }

        return try! response.serializedData()
    }
}
