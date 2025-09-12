import XCTest
@testable import PocketCastsDataModel
@testable import podcasts

class DBTestCase: XCTestCase {
    // We use a single DataManager instance for tests based on DBTestCase,
    // since some tests interact with the download logic.
    // Creating multiple DataManager instances cause the app delegate
    // to reference an outdated one with a closed database.
    // This issue is silently ignored when using FMDB, but GRDB surfaces an error.
    static var dataManager: DataManager!
    var dataManager: DataManager! {
        Self.dataManager
    }
    var downloadManager: DownloadManager!
    var podcast: Podcast!
    var episode: Episode!

    override func setUp() async throws {
        try await super.setUp()
        try setupData()
    }

    private func setupDatabase() throws -> DataManager {
        DataManager.newTestDataManager()
    }

    private func setupData() throws {
        let dataManager = Self.dataManager == nil ? try setupDatabase() : Self.dataManager!
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
        Self.dataManager = dataManager
        self.downloadManager = downloadManager
        self.episode = episode
        self.podcast = podcast
    }

    func setUpQueuedDownload() async throws -> (PodcastManager, URLSessionTask) {
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
        let tasks = await downloadManager.tasks(for: [episode])

        // Ensure there is a task for the episode
        let task = try XCTUnwrap(tasks.first)

        // Check that the task is running to ensure it wasn't already cancelled somehow
        XCTAssertEqual(task.state, URLSessionTask.State.running)

        return (podcastManager, task)
    }
}
