import XCTest
@testable import podcasts
import PocketCastsDataModel

/// Tests for the TOCTOU fix in DownloadManager session selection.
/// Verifies that session selection is based on explicit user approval status,
/// not runtime network state checks.
final class DownloadManagerCellularSessionTests: DBTestCase {

    override func tearDown() {
        super.tearDown()
        cleanupDownloadManager()
    }

    // MARK: - Session Selection Based on AutoDownloadStatus

    /// Verifies that `.userApprovedCellular` status results in cellular session usage,
    /// regardless of current network state.
    func testUserApprovedCellularStatusUsesCellularSession() async throws {
        // Given: An episode with userApprovedCellular status
        let testEpisode = createTestEpisode()

        // When: Performing download with userApprovedCellular status
        await downloadManager.performDownload(
            episode: testEpisode,
            url: testEpisode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .userApprovedCellular,
            retryWithoutUserAgent: false
        )

        // Then: Task should be in cellular session
        let cellularTasks = await downloadManager.cellularBackgroundSession.allTasks
        let wifiTasks = await downloadManager.wifiOnlyBackgroundSession.allTasks

        let taskInCellular = cellularTasks.contains { $0.taskDescription == testEpisode.uuid }
        let taskInWifi = wifiTasks.contains { $0.taskDescription == testEpisode.uuid }

        XCTAssertTrue(taskInCellular, "Task with userApprovedCellular should be in cellular session")
        XCTAssertFalse(taskInWifi, "Task with userApprovedCellular should NOT be in wifi-only session")

        // Cleanup
        dataManager.delete(episodeUuid: testEpisode.uuid)
    }

    /// Verifies that `.notSpecified` status with mobile data disallowed results in
    /// Wi-Fi-only session usage.
    func testNotSpecifiedStatusUsesWifiOnlySessionWhenMobileDataDisallowed() async throws {
        // Given: Mobile data is disallowed and an episode with notSpecified status
        let originalSetting = Settings.mobileDataAllowed()
        Settings.setMobileDataAllowed(false)
        defer { Settings.setMobileDataAllowed(originalSetting) }

        let testEpisode = createTestEpisode()

        // When: Performing download with notSpecified status
        await downloadManager.performDownload(
            episode: testEpisode,
            url: testEpisode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .notSpecified,
            retryWithoutUserAgent: false
        )

        // Then: Task should be in wifi-only session
        let cellularTasks = await downloadManager.cellularBackgroundSession.allTasks
        let wifiTasks = await downloadManager.wifiOnlyBackgroundSession.allTasks

        let taskInCellular = cellularTasks.contains { $0.taskDescription == testEpisode.uuid }
        let taskInWifi = wifiTasks.contains { $0.taskDescription == testEpisode.uuid }

        XCTAssertFalse(taskInCellular, "Task with notSpecified (mobile data disallowed) should NOT be in cellular session")
        XCTAssertTrue(taskInWifi, "Task with notSpecified (mobile data disallowed) should be in wifi-only session")

        // Cleanup
        dataManager.delete(episodeUuid: testEpisode.uuid)
    }

    /// Verifies that `.notSpecified` status with mobile data allowed results in
    /// cellular session usage (per user settings).
    func testNotSpecifiedStatusUsesCellularSessionWhenMobileDataAllowed() async throws {
        // Given: Mobile data is allowed and an episode with notSpecified status
        let originalSetting = Settings.mobileDataAllowed()
        Settings.setMobileDataAllowed(true)
        defer { Settings.setMobileDataAllowed(originalSetting) }

        let testEpisode = createTestEpisode()

        // When: Performing download with notSpecified status
        await downloadManager.performDownload(
            episode: testEpisode,
            url: testEpisode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .notSpecified,
            retryWithoutUserAgent: false
        )

        // Then: Task should be in cellular session (because settings allow it)
        let cellularTasks = await downloadManager.cellularBackgroundSession.allTasks
        let wifiTasks = await downloadManager.wifiOnlyBackgroundSession.allTasks

        let taskInCellular = cellularTasks.contains { $0.taskDescription == testEpisode.uuid }
        let taskInWifi = wifiTasks.contains { $0.taskDescription == testEpisode.uuid }

        XCTAssertTrue(taskInCellular, "Task with notSpecified (mobile data allowed) should be in cellular session")
        XCTAssertFalse(taskInWifi, "Task with notSpecified (mobile data allowed) should NOT be in wifi-only session")

        // Cleanup
        dataManager.delete(episodeUuid: testEpisode.uuid)
    }

    /// Verifies that `.autoDownloaded` status respects auto-download mobile data setting.
    func testAutoDownloadedStatusUsesWifiOnlySessionWhenAutoDownloadMobileDataDisallowed() async throws {
        // Given: Auto-download mobile data is disallowed
        let originalSetting = Settings.autoDownloadMobileDataAllowed()
        Settings.setAutoDownloadMobileDataAllowed(false)
        defer { Settings.setAutoDownloadMobileDataAllowed(originalSetting) }

        let testEpisode = createTestEpisode()

        // When: Performing download with autoDownloaded status
        await downloadManager.performDownload(
            episode: testEpisode,
            url: testEpisode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .autoDownloaded,
            retryWithoutUserAgent: false
        )

        // Then: Task should be in wifi-only session
        let cellularTasks = await downloadManager.cellularBackgroundSession.allTasks
        let wifiTasks = await downloadManager.wifiOnlyBackgroundSession.allTasks

        let taskInCellular = cellularTasks.contains { $0.taskDescription == testEpisode.uuid }
        let taskInWifi = wifiTasks.contains { $0.taskDescription == testEpisode.uuid }

        XCTAssertFalse(taskInCellular, "Task with autoDownloaded (auto mobile data disallowed) should NOT be in cellular session")
        XCTAssertTrue(taskInWifi, "Task with autoDownloaded (auto mobile data disallowed) should be in wifi-only session")

        // Cleanup
        dataManager.delete(episodeUuid: testEpisode.uuid)
    }

    // MARK: - Regression Tests

    /// Regression test: Ensures that notSpecified status does NOT implicitly approve
    /// cellular downloads based on current network state.
    /// This was the original TOCTOU bug.
    func testNotSpecifiedStatusDoesNotImplicitlyApproveCellular() async throws {
        // Given: Mobile data is disallowed (user preference)
        let originalSetting = Settings.mobileDataAllowed()
        Settings.setMobileDataAllowed(false)
        defer { Settings.setMobileDataAllowed(originalSetting) }

        let testEpisode = createTestEpisode()

        // When: Performing download with notSpecified status
        // (Simulating: user queued on Wi-Fi, but network changed to cellular before download started)
        await downloadManager.performDownload(
            episode: testEpisode,
            url: testEpisode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .notSpecified,
            retryWithoutUserAgent: false
        )

        // Then: Task should be in wifi-only session, NOT cellular
        // (The fix ensures we don't assume cellular approval from network state)
        let cellularTasks = await downloadManager.cellularBackgroundSession.allTasks
        let taskInCellular = cellularTasks.contains { $0.taskDescription == testEpisode.uuid }

        XCTAssertFalse(taskInCellular, "notSpecified status should NOT result in cellular session when mobile data is disallowed - this would be the TOCTOU bug")

        // Cleanup
        dataManager.delete(episodeUuid: testEpisode.uuid)
    }

    // MARK: - Helpers

    private func createTestEpisode() -> Episode {
        let testEpisode = Episode()
        testEpisode.uuid = "test-cellular-\(UUID().uuidString)"
        testEpisode.podcastUuid = podcast.uuid
        testEpisode.podcast_id = podcast.id
        testEpisode.downloadUrl = "https://example.com/episode.mp3"
        testEpisode.autoDownloadStatus = AutoDownloadStatus.notSpecified.rawValue
        testEpisode.addedDate = Date()
        dataManager.save(episode: testEpisode)
        return testEpisode
    }

    private func cleanupDownloadManager() {
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            await downloadManager.cancelAllTasks()
            downloadManager.clearDownloadAttempts()
            downloadManager.clearEpisodeCache()
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 5)
    }
}
