@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest

/// Tests for DataManager methods that have complex logic combining data from multiple managers.
/// These tests focus on functionality unique to DataManager that isn't covered by
/// EpisodeDataManagerTests or UserEpisodeDataManagerTests.
final class DataManagerTests: DataManagerTestCase {

    // MARK: - allUpNextEpisodes (combines Episodes + UserEpisodes)

    func testAllUpNextEpisodesReturnsEmptyWhenNoEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let result = dataManager.allUpNextEpisodes()
            XCTAssertTrue(result.isEmpty, "\(impl): should return empty array when no up next episodes")
        }
    }

    func testAllUpNextEpisodesReturnsOnlyEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode1 = createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let episode2 = createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            addToUpNextBottom(episodeUuid: episode1.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode2.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let result = dataManager.allUpNextEpisodes()
            XCTAssertEqual(result.count, 2, "\(impl): should return 2 episodes")
            XCTAssertEqual(result.map(\.uuid), [episode1.uuid, episode2.uuid], "\(impl): should return episodes in order")
        }
    }

    func testAllUpNextEpisodesReturnsOnlyUserEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let userEpisode1 = createTestUserEpisode(uuid: "user-ep-1", dataManager: dataManager)
            let userEpisode2 = createTestUserEpisode(uuid: "user-ep-2", dataManager: dataManager)

            addToUpNextBottom(episodeUuid: userEpisode1.uuid, podcastUuid: DataConstants.userEpisodeFakePodcastId, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: userEpisode2.uuid, podcastUuid: DataConstants.userEpisodeFakePodcastId, dataManager: dataManager)

            let result = dataManager.allUpNextEpisodes()
            XCTAssertEqual(result.count, 2, "\(impl): should return 2 user episodes")
            XCTAssertEqual(result.map(\.uuid), [userEpisode1.uuid, userEpisode2.uuid], "\(impl): should return user episodes in order")
        }
    }

    func testAllUpNextEpisodesReturnsMixedEpisodesInCorrectOrder() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let userEpisode = createTestUserEpisode(uuid: "user-ep-1", dataManager: dataManager)

            // Add user episode first, then regular episode
            addToUpNextBottom(episodeUuid: userEpisode.uuid, podcastUuid: DataConstants.userEpisodeFakePodcastId, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let result = dataManager.allUpNextEpisodes()
            XCTAssertEqual(result.count, 2, "\(impl): should return 2 mixed episodes")
            XCTAssertEqual(result[0].uuid, userEpisode.uuid, "\(impl): user episode should be first")
            XCTAssertEqual(result[1].uuid, episode.uuid, "\(impl): regular episode should be second")
        }
    }

    // MARK: - findBaseEpisode(uuid:) (looks up across both tables)

    func testFindBaseEpisodeByUuidFindsRegularEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "test-episode", podcast: podcast, dataManager: dataManager)

            let found = dataManager.findBaseEpisode(uuid: episode.uuid)
            XCTAssertNotNil(found, "\(impl): should find regular episode")
            XCTAssertEqual(found?.uuid, episode.uuid, "\(impl): should have correct uuid")
            XCTAssertTrue(found is Episode, "\(impl): should be an Episode type")
        }
    }

    func testFindBaseEpisodeByUuidFindsUserEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let userEpisode = createTestUserEpisode(uuid: "test-user-episode", dataManager: dataManager)

            let found = dataManager.findBaseEpisode(uuid: userEpisode.uuid)
            XCTAssertNotNil(found, "\(impl): should find user episode")
            XCTAssertEqual(found?.uuid, userEpisode.uuid, "\(impl): should have correct uuid")
            XCTAssertTrue(found is UserEpisode, "\(impl): should be a UserEpisode type")
        }
    }

    func testFindBaseEpisodeByUuidReturnsNilForNonexistent() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.findBaseEpisode(uuid: "nonexistent-uuid")
            XCTAssertNil(found, "\(impl): should return nil for nonexistent uuid")
        }
    }

    func testFindBaseEpisodeByUuidPrefersUserEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            // Create both episode types with the same UUID (shouldn't happen normally, but tests priority)
            let sharedUuid = "shared-uuid"
            let userEpisode = createTestUserEpisode(uuid: sharedUuid, dataManager: dataManager)

            let found = dataManager.findBaseEpisode(uuid: sharedUuid)
            XCTAssertNotNil(found, "\(impl): should find episode")
            XCTAssertTrue(found is UserEpisode, "\(impl): should prefer UserEpisode when both exist")
            XCTAssertEqual(found?.uuid, userEpisode.uuid, "\(impl): should have correct uuid")
        }
    }

    // MARK: - findBaseEpisode(downloadTaskId:) (looks up across both tables)

    func testFindBaseEpisodeByDownloadTaskIdFindsRegularEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "test-episode", podcast: podcast, downloadTaskId: "task-123", dataManager: dataManager)

            let found = dataManager.findBaseEpisode(downloadTaskId: "task-123")
            XCTAssertNotNil(found, "\(impl): should find regular episode by download task id")
            XCTAssertEqual(found?.uuid, episode.uuid, "\(impl): should have correct uuid")
        }
    }

    func testFindBaseEpisodeByDownloadTaskIdFindsUserEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let userEpisode = createTestUserEpisode(uuid: "test-user-episode", dataManager: dataManager)
            dataManager.saveEpisode(downloadStatus: .downloading, downloadTaskId: "user-task-456", episode: userEpisode)

            let found = dataManager.findBaseEpisode(downloadTaskId: "user-task-456")
            XCTAssertNotNil(found, "\(impl): should find user episode by download task id")
            XCTAssertEqual(found?.uuid, userEpisode.uuid, "\(impl): should have correct uuid")
        }
    }

    func testFindBaseEpisodeByDownloadTaskIdReturnsNilForNonexistent() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.findBaseEpisode(downloadTaskId: "nonexistent-task")
            XCTAssertNil(found, "\(impl): should return nil for nonexistent download task id")
        }
    }

    // MARK: - downloadedEpisodeCount (combines counts from both managers)

    func testDownloadedEpisodeCountCombinesEpisodeAndUserEpisodeCounts() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)

            // Create downloaded regular episodes
            createTestEpisode(uuid: "ep-1", podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            createTestEpisode(uuid: "ep-2", podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            // Create downloaded user episodes
            _ = createTestUserEpisode(uuid: "user-ep-1", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            // Create non-downloaded episodes (shouldn't be counted)
            createTestEpisode(uuid: "ep-3", podcast: podcast, episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)
            _ = createTestUserEpisode(uuid: "user-ep-2", episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            let count = dataManager.downloadedEpisodeCount()
            XCTAssertEqual(count, 3, "\(impl): should return combined count of 3 (2 regular + 1 user)")
        }
    }

    // MARK: - findDownloadedEpisodes (combines and sorts from both managers)

    func testFindDownloadedEpisodesReturnsEmptyWhenNone() throws {
        try runWithBothImplementations { dataManager, impl in
            let episodes = dataManager.findDownloadedEpisodes()
            XCTAssertTrue(episodes.isEmpty, "\(impl): should return empty when no downloaded episodes")
        }
    }

    func testFindDownloadedEpisodesCombinesBothTypes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)

            // Create downloaded regular episode with a specific download date
            let episode = Episode()
            episode.uuid = "downloaded-ep"
            episode.podcastUuid = podcast.uuid
            episode.podcast_id = podcast.id
            episode.addedDate = Date()
            episode.episodeStatus = DownloadStatus.downloaded.rawValue
            episode.lastDownloadAttemptDate = Date(timeIntervalSince1970: 1000)
            dataManager.save(episode: episode)

            // Create downloaded user episode with a more recent download date
            let userEpisode = UserEpisode()
            userEpisode.uuid = "downloaded-user-ep"
            userEpisode.addedDate = Date()
            userEpisode.episodeStatus = DownloadStatus.downloaded.rawValue
            userEpisode.lastDownloadAttemptDate = Date(timeIntervalSince1970: 2000)
            dataManager.save(episode: userEpisode)

            let episodes = dataManager.findDownloadedEpisodes()
            XCTAssertEqual(episodes.count, 2, "\(impl): should return 2 downloaded episodes")

            // Should be sorted by lastDownloadAttemptDate descending (newest first)
            XCTAssertEqual(episodes[0].uuid, userEpisode.uuid, "\(impl): user episode with newer download date should be first")
            XCTAssertEqual(episodes[1].uuid, episode.uuid, "\(impl): regular episode with older download date should be second")
        }
    }

    // MARK: - findEpisodesWhereNotNull (combines results from both managers)

    func testFindEpisodesWhereNotNullCombinesBothTypes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)

            // Create episode with playbackErrorDetails set
            let episode = createTestEpisode(uuid: "ep-with-error", podcast: podcast, dataManager: dataManager)
            dataManager.saveEpisode(playbackError: "Test error", episode: episode)

            // Create user episode with playbackErrorDetails set
            let userEpisode = createTestUserEpisode(uuid: "user-ep-with-error", dataManager: dataManager)
            dataManager.saveEpisode(playbackError: "User error", episode: userEpisode)

            // Create episodes without the property set
            createTestEpisode(uuid: "ep-no-error", podcast: podcast, dataManager: dataManager)
            _ = createTestUserEpisode(uuid: "user-ep-no-error", dataManager: dataManager)

            let episodes = dataManager.findEpisodesWhereNotNull(propertyName: "playbackErrorDetails")
            XCTAssertEqual(episodes.count, 2, "\(impl): should return 2 episodes with non-null playbackErrorDetails")
            let uuids = episodes.map(\.uuid)
            XCTAssertTrue(uuids.contains("ep-with-error"), "\(impl): should include regular episode")
            XCTAssertTrue(uuids.contains("user-ep-with-error"), "\(impl): should include user episode")
        }
    }

    // MARK: - bulkUserFileDelete (routes to correct manager based on type)

    func testBulkUserFileDeleteHandlesMixedTypes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "ep-1", podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            let userEpisode = createTestUserEpisode(uuid: "user-ep-1", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            dataManager.bulkUserFileDelete(baseEpisodes: [episode, userEpisode])

            // Verify both are marked as not downloaded
            let foundEp = dataManager.findEpisode(uuid: "ep-1")
            let foundUserEp = dataManager.findUserEpisode(uuid: "user-ep-1")
            XCTAssertEqual(foundEp?.episodeStatus, DownloadStatus.notDownloaded.rawValue, "\(impl): episode should be not downloaded")
            XCTAssertEqual(foundUserEp?.episodeStatus, DownloadStatus.notDownloaded.rawValue, "\(impl): user episode should be not downloaded")
        }
    }

    // MARK: - episodeInUpNextAt (looks up in Up Next and matches to correct episode table)

    func testEpisodeInUpNextAtReturnsRegularEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "test-episode", podcast: podcast, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let found = dataManager.episodeInUpNextAt(index: 0)
            XCTAssertNotNil(found, "\(impl): should find episode at index 0")
            XCTAssertEqual(found?.uuid, episode.uuid, "\(impl): should have correct uuid")
            XCTAssertTrue(found is Episode, "\(impl): should be Episode type")
        }
    }

    func testEpisodeInUpNextAtReturnsUserEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let userEpisode = createTestUserEpisode(uuid: "test-user-episode", dataManager: dataManager)
            addToUpNextBottom(episodeUuid: userEpisode.uuid, podcastUuid: DataConstants.userEpisodeFakePodcastId, dataManager: dataManager)

            let found = dataManager.episodeInUpNextAt(index: 0)
            XCTAssertNotNil(found, "\(impl): should find user episode at index 0")
            XCTAssertEqual(found?.uuid, userEpisode.uuid, "\(impl): should have correct uuid")
            XCTAssertTrue(found is UserEpisode, "\(impl): should be UserEpisode type")
        }
    }

    func testEpisodeInUpNextAtReturnsNilForEmptyList() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.episodeInUpNextAt(index: 0)
            XCTAssertNil(found, "\(impl): should return nil for empty up next")
        }
    }

    func testEpisodeInUpNextAtReturnsNilForOutOfBoundsIndex() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "test-episode", podcast: podcast, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let found = dataManager.episodeInUpNextAt(index: 5)
            XCTAssertNil(found, "\(impl): should return nil for out of bounds index")
        }
    }

    // MARK: - count(query:values:) (direct SQL execution)

    func testCountQueryReturnsCorrectCount() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            createTestEpisode(uuid: "ep-2", podcast: podcast, dataManager: dataManager)
            createTestEpisode(uuid: "ep-3", podcast: podcast, dataManager: dataManager)

            let count = dataManager.count(
                query: "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ?",
                values: [podcast.id]
            )
            XCTAssertEqual(count, 3, "\(impl): should return count of 3")
        }
    }

    func testCountQueryReturnsZeroForNoMatches() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = dataManager.count(
                query: "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ?",
                values: [999]
            )
            XCTAssertEqual(count, 0, "\(impl): should return 0 for no matches")
        }
    }

    // MARK: - findEpisodeCount

    func testFindEpisodeCountReturnsPodcastEpisodeCount() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            createTestEpisode(uuid: "ep-2", podcast: podcast, dataManager: dataManager)
            createTestEpisode(uuid: "ep-3", podcast: podcast, dataManager: dataManager)

            // Create another podcast with episodes that shouldn't be counted
            let otherPodcast = createTestPodcast(uuid: "other-podcast", dataManager: dataManager)
            createTestEpisode(uuid: "other-ep", podcast: otherPodcast, dataManager: dataManager)

            let count = dataManager.findEpisodeCount(podcastId: podcast.id)
            XCTAssertEqual(count, 3, "\(impl): should return 3 episodes for the podcast")
        }
    }

    // MARK: - playlistEpisodeCount (Up Next count)

    func testPlaylistEpisodeCountReturnsZeroForEmpty() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = dataManager.playlistEpisodeCount()
            XCTAssertEqual(count, 0, "\(impl): should return 0 for empty playlist")
        }
    }

    func testPlaylistEpisodeCountReturnsCorrectCount() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode1 = createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            let episode2 = createTestEpisode(uuid: "ep-2", podcast: podcast, dataManager: dataManager)

            addToUpNextBottom(episodeUuid: episode1.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode2.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let count = dataManager.playlistEpisodeCount()
            XCTAssertEqual(count, 2, "\(impl): should return 2 for playlist with 2 episodes")
        }
    }

    // MARK: - positionForPlaylistEpisode (Up Next position calculation)

    func testPositionForPlaylistEpisodeBottomOfList() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let position = dataManager.positionForPlaylistEpisode(bottomOfList: true)
            XCTAssertEqual(position, 1, "\(impl): should return position 1 for bottom of list when 1 episode exists")
        }
    }

    func testPositionForPlaylistEpisodeTopOfList() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let position = dataManager.positionForPlaylistEpisode(bottomOfList: false)
            XCTAssertEqual(position, 0, "\(impl): should return position 0 for top of list")
        }
    }

    // MARK: - updateEpisodePlaybackInteractionDate (routing based on episode type)

    func testUpdateEpisodePlaybackInteractionDateUpdatesForEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = createTestPodcast(dataManager: dataManager)
            let episode = createTestEpisode(uuid: "test-episode", podcast: podcast, lastPlaybackInteractionDate: nil, dataManager: dataManager)

            dataManager.updateEpisodePlaybackInteractionDate(episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertNotNil(found?.lastPlaybackInteractionDate, "\(impl): should set playback interaction date")
        }
    }

    func testUpdateEpisodePlaybackInteractionDateIgnoresUserEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            // This test verifies that calling updateEpisodePlaybackInteractionDate on a UserEpisode
            // does nothing (since UserEpisode doesn't have lastPlaybackInteractionDate in the same way)
            let userEpisode = createTestUserEpisode(uuid: "test-user-episode", dataManager: dataManager)

            // This should not crash and should be a no-op
            dataManager.updateEpisodePlaybackInteractionDate(episode: userEpisode)

            // Just verify the user episode still exists
            let found = dataManager.findUserEpisode(uuid: userEpisode.uuid)
            XCTAssertNotNil(found, "\(impl): user episode should still exist")
        }
    }
}
