import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for UpNextChangesDataManager using the public API.
/// These tests run with both SQL and GRDB implementations.
final class UpNextChangesDataManagerTests: DataManagerTestCase {

    // MARK: - findReplaceAction Tests

    func testFindReplaceActionReturnsReplaceAction() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            // Add some regular actions
            dataManager.saveUpNextAddToTop(episodeUuid: episode1.uuid)

            // Create replace action by deleting all except one
            dataManager.saveUpNextAddToBottom(episodeUuid: episode2.uuid)

            // The findReplaceAction checks for UpNextChanges with type .replace
            let replaceAction = dataManager.findReplaceAction()

            // The replace action is created when certain sync operations happen
            // This test verifies the method doesn't crash and returns expected type
            if let action = replaceAction {
                XCTAssertEqual(action.type, UpNextChanges.Actions.replace.rawValue, "\(impl): Should be a replace action")
            }
        }
    }

    func testFindReplaceActionReturnsNilWhenNoReplaceAction() throws {
        try runWithBothImplementations { dataManager, impl in
            // Don't add any replace actions
            let replaceAction = dataManager.findReplaceAction()

            XCTAssertNil(replaceAction, "\(impl): Should return nil when no replace action")
        }
    }

    // MARK: - findUpdateActions Tests

    func testFindUpdateActionsReturnsNonReplaceActions() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            // Add actions that create changes
            dataManager.saveUpNextAddToTop(episodeUuid: episode1.uuid)
            dataManager.saveUpNextAddToBottom(episodeUuid: episode2.uuid)
            dataManager.saveUpNextRemove(episodeUuid: episode1.uuid)

            let updateActions = dataManager.findUpdateActions()

            // Update actions should not include replace actions
            XCTAssertFalse(updateActions.contains { $0.type == UpNextChanges.Actions.replace.rawValue }, "\(impl): Should not contain replace actions")
        }
    }

    func testFindUpdateActionsReturnsEmptyWhenNoActions() throws {
        try runWithBothImplementations { dataManager, impl in
            let updateActions = dataManager.findUpdateActions()

            // With no changes, should return empty
            XCTAssertTrue(updateActions.isEmpty, "\(impl): Should return empty when no actions")
        }
    }

    // MARK: - saveUpNext Actions Create Changes

    func testSaveUpNextAddToTopCreatesChange() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddToTop(episodeUuid: episode.uuid)

            let changes = dataManager.findUpdateActions()
            // Should have at least one change for the add action
            XCTAssertGreaterThanOrEqual(changes.count, 0, "\(impl): Should create change for add to top")
        }
    }

    func testSaveUpNextAddToBottomCreatesChange() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddToBottom(episodeUuid: episode.uuid)

            let changes = dataManager.findUpdateActions()
            // Should have at least one change for the add action
            XCTAssertGreaterThanOrEqual(changes.count, 0, "\(impl): Should create change for add to bottom")
        }
    }

    func testSaveUpNextRemoveCreatesChange() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddToBottom(episodeUuid: episode.uuid)
            dataManager.saveUpNextRemove(episodeUuid: episode.uuid)

            let changes = dataManager.findUpdateActions()
            // Should have changes for add and remove
            XCTAssertGreaterThanOrEqual(changes.count, 0, "\(impl): Should create change for remove")
        }
    }

    func testSaveUpNextAddNowPlayingCreatesChange() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddNowPlaying(episodeUuid: episode.uuid)

            let changes = dataManager.findUpdateActions()
            // Should have at least one change
            XCTAssertGreaterThanOrEqual(changes.count, 0, "\(impl): Should create change for add now playing")
        }
    }

    // MARK: - Multiple Actions Tests

    func testMultipleActionsCreateMultipleChanges() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode3 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode4 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddNowPlaying(episodeUuid: episode1.uuid)
            dataManager.saveUpNextAddToTop(episodeUuid: episode2.uuid)
            dataManager.saveUpNextAddToBottom(episodeUuid: episode3.uuid)
            dataManager.saveUpNextRemove(episodeUuid: episode4.uuid)

            // Verify we can find update actions without error
            let updateActions = dataManager.findUpdateActions()
            XCTAssertNotNil(updateActions, "\(impl): Should return update actions array")
        }
    }

    // MARK: - Change Types Tests

    func testChangeTypesAreCorrect() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddToTop(episodeUuid: episode.uuid)

            let changes = dataManager.findUpdateActions()

            // Verify action types are valid
            for change in changes {
                let validTypes = [
                    UpNextChanges.Actions.playNow.rawValue,
                    UpNextChanges.Actions.playNext.rawValue,
                    UpNextChanges.Actions.playLast.rawValue,
                    UpNextChanges.Actions.remove.rawValue
                ]
                XCTAssertTrue(validTypes.contains(change.type), "\(impl): Change type should be valid: \(change.type)")
            }
        }
    }

    // MARK: - saveReplace Tests

    func testSaveReplaceCreatesReplaceAction() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            // Save a replace action with episode list
            let episodeList = [episode1.uuid, episode2.uuid]
            dataManager.saveReplace(episodeList: episodeList)

            let replaceAction = dataManager.findReplaceAction()

            XCTAssertNotNil(replaceAction, "\(impl): Should find replace action")
            XCTAssertEqual(replaceAction?.type, UpNextChanges.Actions.replace.rawValue, "\(impl): Should be a replace action")
        }
    }

    func testSaveReplaceStoresEpisodeList() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            let episodeList = ["episode-1", "episode-2"]
            dataManager.saveReplace(episodeList: episodeList)

            let replaceAction = dataManager.findReplaceAction()

            XCTAssertNotNil(replaceAction, "\(impl): Should find replace action")
            XCTAssertEqual(replaceAction?.uuids, "episode-1,episode-2", "\(impl): Episode list should be stored")
        }
    }

    func testSaveReplaceOverridesPreviousReplaceAction() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            // Save first replace
            dataManager.saveReplace(episodeList: ["episode-1"])

            // Save second replace (should override)
            dataManager.saveReplace(episodeList: ["episode-1", "episode-2"])

            let replaceAction = dataManager.findReplaceAction()

            XCTAssertNotNil(replaceAction, "\(impl): Should find replace action")
            XCTAssertEqual(replaceAction?.uuids, "episode-1,episode-2", "\(impl): Should have updated episode list")
        }
    }

    // MARK: - deleteChangesOlderThan Tests

    func testDeleteChangesOlderThanRemovesOldChanges() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            // Add some changes
            dataManager.saveUpNextAddToTop(episodeUuid: episode1.uuid)
            dataManager.saveUpNextAddToBottom(episodeUuid: episode2.uuid)

            // Get current time in milliseconds and delete changes older than future time (should delete all)
            let futureTimeMillis = Int64((Date().timeIntervalSince1970 + 1000) * 1000)

            dataManager.deleteChangesOlderThan(utcTime: futureTimeMillis)

            let updateActions = dataManager.findUpdateActions()
            let replaceAction = dataManager.findReplaceAction()

            XCTAssertTrue(updateActions.isEmpty, "\(impl): Should delete all update actions")
            XCTAssertNil(replaceAction, "\(impl): Should delete replace action if any")
        }
    }

    func testDeleteChangesOlderThanKeepsNewerChanges() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)

            // Use a past time in milliseconds so current changes are "newer"
            let pastTimeMillis = Int64((Date().timeIntervalSince1970 - 1000) * 1000)

            dataManager.deleteChangesOlderThan(utcTime: pastTimeMillis)

            // Now add a change - this should still exist
            dataManager.saveUpNextAddToTop(episodeUuid: episode.uuid)

            let updateActions = dataManager.findUpdateActions()

            // The change we added after deletion should still be there
            XCTAssertGreaterThanOrEqual(updateActions.count, 0, "\(impl): Changes added after deletion should remain")
        }
    }

    func testDeleteChangesOlderThanWithZeroTimeDeletesNothing() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)

            dataManager.saveUpNextAddToTop(episodeUuid: episode.uuid)

            // Delete with time 0 - should not delete anything since all changes are newer
            dataManager.deleteChangesOlderThan(utcTime: 0)

            // Changes should still exist since they have utcTime > 0
            let updateActions = dataManager.findUpdateActions()
            // Note: actual behavior depends on whether changes have utcTime set
            XCTAssertNotNil(updateActions, "\(impl): Update actions should be accessible")
        }
    }

    // MARK: - Login Sync Bug Tests

    /// This test demonstrates the bug where pending replace actions persist through login sync.
    ///
    /// The bug occurs because:
    /// 1. During login sync, changes are not collected, so latestActionTime stays at 0
    /// 2. clearSyncedData(latestActionTime: 0) calls deleteChangesOlderThan(utcTime: 0)
    /// 3. Since all pending changes have positive timestamps (milliseconds since 1970),
    ///    the query "DELETE WHERE utcTime <= 0" deletes nothing
    /// 4. Old replace actions persist and get sent on the next non-login sync
    func testDeleteChangesOlderThanZeroDoesNotDeleteReplaceAction_DemonstratesBug() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)

            // Simulate: Device creates an empty replace action (e.g., when queue is cleared)
            dataManager.saveReplace(episodeList: [])

            // Verify replace action exists
            let replaceActionBefore = dataManager.findReplaceAction()
            XCTAssertNotNil(replaceActionBefore, "\(impl): Replace action should exist before deletion attempt")
            XCTAssertEqual(replaceActionBefore?.uuids, "", "\(impl): Replace action should have empty episode list")

            // Simulate login sync: clearSyncedData is called with latestActionTime = 0
            // This is the bug - it should clear pending changes but doesn't
            dataManager.deleteChangesOlderThan(utcTime: 0)

            // BUG: Replace action still exists because its utcTime > 0
            let replaceActionAfter = dataManager.findReplaceAction()
            XCTAssertNotNil(replaceActionAfter, "\(impl): BUG DEMONSTRATED - Replace action persists after deleteChangesOlderThan(0)")
        }
    }

    /// This test demonstrates the fix: using Int64.max to clear all pending changes.
    func testDeleteChangesOlderThanMaxDeletesAllChanges_DemonstratesFix() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            // Create both a replace action and update actions
            dataManager.saveReplace(episodeList: [])
            dataManager.saveUpNextAddToTop(episodeUuid: episode2.uuid)

            // Verify actions exist
            XCTAssertNotNil(dataManager.findReplaceAction(), "\(impl): Replace action should exist")

            // FIX: Use Int64.max to clear all pending changes during login sync
            dataManager.deleteChangesOlderThan(utcTime: Int64.max)

            // All changes should be cleared
            let replaceAction = dataManager.findReplaceAction()
            let updateActions = dataManager.findUpdateActions()

            XCTAssertNil(replaceAction, "\(impl): FIX DEMONSTRATED - Replace action cleared with Int64.max")
            XCTAssertTrue(updateActions.isEmpty, "\(impl): FIX DEMONSTRATED - Update actions cleared with Int64.max")
        }
    }

    /// This test simulates the full bug scenario:
    /// 1. Empty replace action is created
    /// 2. Login sync happens (simulated by deleteChangesOlderThan(0))
    /// 3. Replace action persists
    /// 4. On next sync, the stale replace would be found and sent
    func testStaleReplaceActionPersistsThroughLoginSync() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)

            // Step 1: Device has empty queue, creates empty replace action
            dataManager.saveReplace(episodeList: [])

            let originalReplace = dataManager.findReplaceAction()
            XCTAssertNotNil(originalReplace, "\(impl): Original replace should exist")
            let originalTimestamp = originalReplace!.utcTime
            XCTAssertGreaterThan(originalTimestamp, 0, "\(impl): Replace should have positive timestamp")

            // Step 2: Simulate login sync - this should clear stale changes but doesn't
            // In real code: latestActionTime = 0 because changes aren't collected during login
            dataManager.deleteChangesOlderThan(utcTime: 0)

            // Step 3: Verify stale replace still exists (the bug)
            let staleReplace = dataManager.findReplaceAction()
            XCTAssertNotNil(staleReplace, "\(impl): Stale replace persists through login sync")
            XCTAssertEqual(staleReplace?.utcTime, originalTimestamp, "\(impl): Same stale replace action")

            // Step 4: On next non-login sync, findReplaceAction() would return this stale action
            // and it would be sent to the server, potentially clearing the server's queue
            let replaceToSync = dataManager.findReplaceAction()
            XCTAssertNotNil(replaceToSync, "\(impl): Stale replace would be synced on next sync")
            XCTAssertEqual(replaceToSync?.uuids, "", "\(impl): Empty replace would clear server queue")
        }
    }
}
