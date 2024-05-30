import XCTest
import FMDB
import PocketCastsDataModel
@testable import podcasts

final class PodcastManagerTests: DBTestCase {
    func testTaskCancellationForUnusednDeletion() async throws {
        let (podcastManager, task) = try await setUpQueuedDownload()

        // Create a predicate + expectation to check when task state is completed
        let predicate = NSPredicate(block: { _, _ -> Bool in
            return task.state == .completed
        })
        let publishExpectation = XCTNSPredicateExpectation(predicate: predicate, object: task)

        // This should delete the podcast given the mock data
        await podcastManager.deletePodcastIfUnused(podcast)

        // Verify the podcast has been removed from the data manager
        XCTAssertNil(dataManager.findPodcast(uuid: podcast.uuid))

        // Wait for the task to fulfill the completion expectation: that it is completed
        await fulfillment(of: [publishExpectation])

        // Check that the download task has been cancelled as a result of deleting the podcast
        let error = task.error as? NSError
        XCTAssertEqual(error?.domain, NSURLErrorDomain, "Task should be cancelled")
        XCTAssertEqual(error?.code, NSURLErrorCancelled, "Task should be cancelled")
    }
}
