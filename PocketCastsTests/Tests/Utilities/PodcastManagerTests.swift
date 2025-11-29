import XCTest
import PocketCastsDataModel
import PocketCastsServer
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

    func testUnsubscribeKeepsDownloadsInPlaylist() throws {
        ServerSettings.setSyncingEmail(email: "test@example.com")
        defer { ServerSettings.setSyncingEmail(email: nil) }

        let (podcast, episode) = makeDownloadedPodcastAndEpisode()
        let playlist = EpisodeFilter()
        playlist.uuid = UUID().uuidString
        playlist.playlistName = "Keep Downloads"
        playlist.manual = true
        dataManager.save(playlist: playlist)
        dataManager.add(episodes: [episode], to: playlist)

        let podcastManager = PodcastManager(dataManager: dataManager, downloadManager: downloadManager)
        podcastManager.unsubscribe(podcast: podcast)

        let refreshedEpisode = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshedEpisode.episodeStatus, DownloadStatus.downloaded.rawValue)
        XCTAssertTrue(FileManager.default.fileExists(atPath: DownloadManager.shared.pathForEpisode(refreshedEpisode)))
    }

    func testUnsubscribeRemovesDownloadsNotInPlaylist() throws {
        ServerSettings.setSyncingEmail(email: "test@example.com")
        defer { ServerSettings.setSyncingEmail(email: nil) }

        let (podcast, episode) = makeDownloadedPodcastAndEpisode()
        let podcastManager = PodcastManager(dataManager: dataManager, downloadManager: downloadManager)

        podcastManager.unsubscribe(podcast: podcast)

        let refreshedEpisode = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshedEpisode.episodeStatus, DownloadStatus.notDownloaded.rawValue)
        XCTAssertFalse(FileManager.default.fileExists(atPath: DownloadManager.shared.pathForEpisode(refreshedEpisode)))
    }

    private func makeDownloadedPodcastAndEpisode() -> (Podcast, Episode) {
        let podcast = Podcast()
        podcast.uuid = UUID().uuidString
        podcast.subscribed = 0
        podcast.addedDate = Date().addingTimeInterval(-2.weeks)
        podcast.syncStatus = SyncStatus.synced.rawValue
        dataManager.save(podcast: podcast)

        let episode = Episode()
        episode.uuid = UUID().uuidString
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.addedDate = podcast.addedDate
        episode.downloadUrl = "http://example.com/audio"
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = DownloadStatus.downloaded.rawValue
        dataManager.save(episode: episode)

        createDownloadedFile(for: episode)

        return (podcast, episode)
    }

    private func createDownloadedFile(for episode: Episode) {
        let path = DownloadManager.shared.pathForEpisode(episode)
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: path, contents: Data())
    }
}
