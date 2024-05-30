import XCTest
import FMDB
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
}
