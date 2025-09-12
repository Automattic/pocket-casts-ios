import XCTest
@testable import podcasts
import PocketCastsDataModel

final class DownloadManagerRetryTests: DBTestCase {

    override func tearDown() {
        super.tearDown()
        cleanupDownloadManager()
    }

    // MARK: - Retry Without User-Agent Tests

    func testRetryDownloadWithoutUserAgent_CallsPerformDownloadWithCorrectParameters() async throws {
        // Create a mock episode with download URL
        let mockEpisode = Episode()
        mockEpisode.uuid = UUID().uuidString
        mockEpisode.podcastUuid = podcast.uuid
        mockEpisode.podcast_id = podcast.id
        mockEpisode.downloadUrl = "https://example.com/episode.mp3"
        mockEpisode.autoDownloadStatus = AutoDownloadStatus.autoDownloaded.rawValue
        mockEpisode.addedDate = Date()
        dataManager.save(episode: mockEpisode)

        // Test the retry method
        await downloadManager.retryDownloadWithoutUserAgent(episode: mockEpisode)

        // Verify that a task was created
        let tasks = await downloadManager.tasks(for: [mockEpisode])
        XCTAssertEqual(tasks.count, 1, "Should create a retry task")

        // Verify the retry state is tracked in the downloadAttempts dictionary
        let task = try XCTUnwrap(tasks.first)
        XCTAssertEqual(task.taskDescription, mockEpisode.uuid, "Task description should be clean (just episode UUID)")

        // Check the new tracking system
        if let attempt = downloadManager.getDownloadAttempt(for: task.taskIdentifier) {
            XCTAssertTrue(attempt.hasRetriedWithoutUserAgent, "Should indicate retry without User-Agent in tracking system")
            XCTAssertEqual(attempt.episodeUuid, mockEpisode.uuid, "Should track correct episode UUID")
        } else {
            XCTFail("Should have download attempt tracking data")
        }
    }

    func testRetryDownloadWithoutUserAgent_DoesNothingWhenNoDownloadUrl() async throws {
        // Create a mock episode without download URL
        let mockEpisode = Episode()
        mockEpisode.uuid = UUID().uuidString
        mockEpisode.podcastUuid = podcast.uuid
        mockEpisode.podcast_id = podcast.id
        mockEpisode.downloadUrl = nil
        mockEpisode.addedDate = Date()
        dataManager.save(episode: mockEpisode)

        // Test the retry method
        await downloadManager.retryDownloadWithoutUserAgent(episode: mockEpisode)

        // Verify that no task was created
        let tasks = await downloadManager.tasks(for: [mockEpisode])
        XCTAssertEqual(tasks.count, 0, "Should not create a task when there's no download URL")
    }

    // MARK: - Integration Tests

    func testPerformDownload_WithRetryFlag_CreatesTaskWithRetryDescription() async throws {
        await downloadManager.performDownload(
            episode: episode,
            url: episode.downloadUrl ?? "",
            previousDownloadFailed: true,
            fireNotification: false,
            autoDownloadStatus: .notSpecified,
            retryWithoutUserAgent: true
        )

        let tasks = await downloadManager.tasks(for: [episode])
        let task = try XCTUnwrap(tasks.first)

        // Check the new tracking system for retry state
        if let attempt = downloadManager.getDownloadAttempt(for: task.taskIdentifier) {
            XCTAssertTrue(attempt.hasRetriedWithoutUserAgent, "Should indicate retry without User-Agent in tracking system")
        } else {
            XCTFail("Should have download attempt tracking data")
        }
    }

    func testPerformDownload_WithoutRetryFlag_CreatesNormalTaskDescription() async throws {
        await downloadManager.performDownload(
            episode: episode,
            url: episode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .notSpecified,
            retryWithoutUserAgent: false
        )

        let tasks = await downloadManager.tasks(for: [episode])
        let task = try XCTUnwrap(tasks.first)

        // Check the new tracking system for non-retry state
        if let attempt = downloadManager.getDownloadAttempt(for: task.taskIdentifier) {
            XCTAssertFalse(attempt.hasRetriedWithoutUserAgent, "Should not indicate retry for normal download in tracking system")
        } else {
            XCTFail("Should have download attempt tracking data")
        }
    }

    private func cleanupDownloadManager() {
        // Use runBlocking to wait for async cleanup to complete
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            await downloadManager.cancelAllTasks()
            downloadManager.clearDownloadAttempts()
            downloadManager.clearEpisodeCache()

            semaphore.signal()
        }

        // Wait for cleanup to complete
        _ = semaphore.wait(timeout: .now() + 5)
    }
}

// MARK: - Extensions to expose private methods for testing

extension DownloadManager {
    func shouldRetryWithoutUserAgent(task: URLSessionDownloadTask) -> Bool {
        guard let attempt = downloadAttempts[task.taskIdentifier] else { return false }
        return !attempt.hasRetriedWithoutUserAgent
    }

    func retryDownloadWithoutUserAgent(episode: BaseEpisode) async {
        guard let downloadUrl = episode.downloadUrl else {
            return
        }

        let autoDownloadStatus = AutoDownloadStatus(rawValue: episode.autoDownloadStatus) ?? .notSpecified
        await performDownload(episode: episode, url: downloadUrl, previousDownloadFailed: true, fireNotification: true, autoDownloadStatus: autoDownloadStatus, retryWithoutUserAgent: true)
    }

    func episodeForTask(_ task: URLSessionDownloadTask, forceReload: Bool) -> BaseEpisode? {
        guard let taskDescription = task.taskDescription else { return nil }

        if !forceReload {
            if let episode = downloadingEpisodesCache[taskDescription] {
                return episode
            }
        }

        let episode = dataManager.findBaseEpisode(downloadTaskId: taskDescription)
        if let episode = episode {
            downloadingEpisodesCache[taskDescription] = episode
        }

        return episode
    }

    // Test helper to access download attempts tracking
    func getDownloadAttempt(for taskIdentifier: Int) -> (episodeUuid: String, originalUrl: URL, hasRetriedWithoutUserAgent: Bool)? {
        guard let attempt = downloadAttempts[taskIdentifier] else { return nil }
        return (attempt.episodeUuid, attempt.originalUrl, attempt.hasRetriedWithoutUserAgent)
    }

    // Test cleanup methods
    func cancelAllTasks() async {
        let tasks = await allTasks()
        for task in tasks {
            downloadAttempts.removeValue(forKey: task.taskIdentifier)
            task.cancel()
        }
    }

    func clearDownloadAttempts() {
        downloadAttempts.removeAll()
    }

    func clearEpisodeCache() {
        // Clear downloadingEpisodesCache based on its type
        if let cache = downloadingEpisodesCache as? ThreadSafeDictionary<String, BaseEpisode> {
            cache.removeAll()
        } else if var cache = downloadingEpisodesCache as? Dictionary<String, BaseEpisode> {
            cache.removeAll()
        }
    }
}
