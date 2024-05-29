import XCTest
import FMDB
@testable import podcasts
import PocketCastsDataModel

final class DownloadManagerTests: XCTestCase {

    private func setupDatabase() throws -> DataManager {
            let dbQueue = try XCTUnwrap(FMDatabaseQueue.newTestDatabase())
            return DataManager(dbQueue: dbQueue)
        }

    private var dataManager: DataManager!
    private var downloadManager: DownloadManager!
    private var podcast: Podcast!
    private var episode: Episode!

    override func setUp() async throws {
        try await super.setUp()

        let dataManager = try setupDatabase()
        let downloadManager = DownloadManager(dataManager: dataManager)

        let podcast = Podcast()
        podcast.uuid = UUID().uuidString
        podcast.subscribed = 0
        podcast.addedDate = Date().addingTimeInterval(-1.week)
        podcast.syncStatus = SyncStatus.synced.rawValue

        dataManager.save(podcast: podcast)

        let episode = Episode()
        episode.uuid = UUID().uuidString
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.addedDate = podcast.addedDate
        episode.downloadUrl = "http://google.com"
        episode.playingStatus = PlayingStatus.notPlayed.rawValue

        dataManager.save(episode: episode)
        self.dataManager = dataManager
        self.downloadManager = downloadManager
        self.episode = episode
        self.podcast = podcast
    }

    func testStuckSingleDownload() async throws {
        let podcastManager = PodcastManager(dataManager: dataManager, downloadManager: downloadManager)

        // Verify the podcast and episode exist in the data manager after being added in `setUp`
        XCTAssertEqual(dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true), podcast)
        XCTAssertEqual(dataManager.findEpisode(uuid: episode.uuid), episode)

        // Add the episode to the download queue
        await downloadManager.performAddToQueue(
            episode: episode,
            url: episode.downloadUrl ?? "",
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .notSpecified
        )

        // Retrieve the download tasks for the episode
        let tasks = await DownloadManager.shared.tasks(for: [episode])

        // Ensure there is a task for the episode
        let task = try XCTUnwrap(tasks.first)

        // Check that the task is running to ensure it wasn't already cancelled somehow
        XCTAssertEqual(task.state, URLSessionTask.State.running)

        // Create a predicate + expectation to check when task state is completed
        let predicate = NSPredicate(block: { _, _ -> Bool in
            return task.state == .completed
        })
        let publishExpectation = XCTNSPredicateExpectation(predicate: predicate, object: task)

        // This should delete the podcast given the mock data
        dataManager.delete(episodeUuid: episode.uuid)

        // Verify the podcast has been removed from the data manager
        XCTAssertNil(dataManager.findEpisode(uuid: episode.uuid))

        await DownloadManager.shared.clearStuckDownloads()

        // Wait for the task to fulfill the completion expectation: that is is completed
        await fulfillment(of: [publishExpectation])

        // Check that the download task has been cancelled as a result of deleting the podcast
        let error = task.error as? NSError
        XCTAssertEqual(error?.domain, NSURLErrorDomain, "Task should be cancelled")
        XCTAssertEqual(error?.code, NSURLErrorCancelled, "Task should be cancelled")
    }
}
