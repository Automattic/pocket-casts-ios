import XCTest
@testable import podcasts
import PocketCastsDataModel

final class DownloadManagerTests: DBTestCase {
    func testStuckSingleDownload() async throws {
        let (_, task) = try await setUpQueuedDownload()

        // Create a predicate + expectation to check when task state is completed
        let predicate = NSPredicate(block: { _, _ -> Bool in
            return task.state == .completed
        })
        let publishExpectation = XCTNSPredicateExpectation(predicate: predicate, object: task)

        // This should delete the podcast given the mock data
        dataManager.delete(episodeUuid: episode.uuid)

        // Verify the episode has been removed from the data manager
        XCTAssertNil(dataManager.findEpisode(uuid: episode.uuid))

        await DownloadManager.shared.clearStuckDownloads()

        // Wait for the task to fulfill the completion expectation: that it is completed
        await fulfillment(of: [publishExpectation])

        // Check that the download task has been cancelled as a result of deleting the episode
        let error = task.error as? NSError
        XCTAssertEqual(error?.domain, NSURLErrorDomain, "Task should be cancelled")
        XCTAssertEqual(error?.code, NSURLErrorCancelled, "Task should be cancelled")
    }

    func testProcessEpisodeRemovesTempFileWhenMoveSucceeds() {
        // Given: A successfully downloaded episode
        let testEpisode = Episode()
        testEpisode.uuid = "test-move-\(UUID().uuidString)"
        testEpisode.podcastUuid = podcast.uuid
        testEpisode.podcast_id = podcast.id
        testEpisode.autoDownloadStatus = AutoDownloadStatus.notSpecified.rawValue
        dataManager.save(episode: testEpisode)

        let fileManager = FileManager.default
        let tempFilePath = downloadManager.tempPathForEpisode(testEpisode)
        let destinationPath = downloadManager.pathForEpisode(testEpisode)

        // Create a temp file with test data (must be at least 10KB to pass validation)
        let testData = Data(repeating: 0, count: 10 * 1024)
        fileManager.createFile(atPath: tempFilePath, contents: testData)

        // Verify temp file exists
        XCTAssertTrue(fileManager.fileExists(atPath: tempFilePath), "Temp file should exist before processing")

        // When: Processing the episode with copyFile: false (move operation)
        let tempFileURL = URL(fileURLWithPath: tempFilePath)
        downloadManager.processEpisode(testEpisode, downloadedFile: tempFileURL, reportedContentType: "audio/mpeg", copyFile: false)

        // Then: Temp file should be removed (moved to destination)
        XCTAssertFalse(fileManager.fileExists(atPath: tempFilePath), "Temp file should be removed after move")
        XCTAssertTrue(fileManager.fileExists(atPath: destinationPath), "Destination file should exist")

        // Cleanup
        try? fileManager.removeItem(atPath: destinationPath)
        dataManager.delete(episodeUuid: testEpisode.uuid)
    }
}
