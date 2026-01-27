import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for EpisodeDataManager using the public API.
/// These tests run with both SQL and GRDB implementations.
final class EpisodeDataManagerTests: DataManagerTestCase {

    // MARK: - findEpisode Tests

    func testFindEpisodeByUuidReturnsEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "test-episode-uuid", podcast: podcast, dataManager: dataManager)

            let found = dataManager.findEpisode(uuid: "test-episode-uuid")

            XCTAssertNotNil(found, "\(impl): Should find episode")
            XCTAssertEqual(found?.uuid, episode.uuid, "\(impl): UUID should match")
        }
    }

    func testFindEpisodeByUuidReturnsNilForNonExistent() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.findEpisode(uuid: "non-existent-uuid")

            XCTAssertNil(found, "\(impl): Should not find non-existent episode")
        }
    }

    // MARK: - allEpisodesForPodcast Tests

    func testAllEpisodesForPodcastReturnsAllEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 1", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 2", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 3", dataManager: dataManager)

            let episodes = dataManager.allEpisodesForPodcast(id: podcast.id)

            XCTAssertEqual(episodes.count, 3, "\(impl): Should return 3 episodes")
        }
    }

    func testAllEpisodesForPodcastExcludesDeletedEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 1", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Deleted Episode", wasDeleted: true, dataManager: dataManager)

            let episodes = dataManager.allEpisodesForPodcast(id: podcast.id)

            XCTAssertEqual(episodes.count, 1, "\(impl): Should exclude deleted episode")
            XCTAssertEqual(episodes.first?.title, "Episode 1", "\(impl): Should return non-deleted episode")
        }
    }

    func testAllEpisodesForPodcastReturnsEmptyForNoPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let episodes = dataManager.allEpisodesForPodcast(id: 999)

            XCTAssertTrue(episodes.isEmpty, "\(impl): Should return empty array for non-existent podcast")
        }
    }

    // MARK: - findLatestEpisode Tests

    func testFindLatestEpisodeReturnsLatest() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Older Episode", publishedDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager)
            let latestEpisode = self.createTestEpisode(podcast: podcast, title: "Latest Episode", publishedDate: Date(), dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Old Episode", publishedDate: Date(timeIntervalSinceNow: -172800), dataManager: dataManager)

            let found = dataManager.findLatestEpisode(podcast: podcast)

            XCTAssertNotNil(found, "\(impl): Should find latest episode")
            XCTAssertEqual(found?.title, latestEpisode.title, "\(impl): Should return latest episode")
        }
    }

    func testFindLatestEpisodeExcludesDeleted() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Latest Deleted", publishedDate: Date(), wasDeleted: true, dataManager: dataManager)
            let olderEpisode = self.createTestEpisode(podcast: podcast, title: "Older Episode", publishedDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager)

            let found = dataManager.findLatestEpisode(podcast: podcast)

            XCTAssertNotNil(found, "\(impl): Should find episode")
            XCTAssertEqual(found?.title, olderEpisode.title, "\(impl): Should skip deleted and return older episode")
        }
    }

    func testFindLatestEpisodeReturnsNilForEmptyPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)

            let found = dataManager.findLatestEpisode(podcast: podcast)

            XCTAssertNil(found, "\(impl): Should return nil for podcast with no episodes")
        }
    }

    // MARK: - findLatestEpisodes Tests

    func testFindLatestEpisodesRespectsLimit() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            for i in 0..<10 {
                _ = self.createTestEpisode(podcast: podcast, title: "Episode \(i)", publishedDate: Date(timeIntervalSinceNow: Double(-i * 86400)), dataManager: dataManager)
            }

            let episodes = dataManager.findLatestEpisodes(podcast: podcast, limit: 5)

            XCTAssertEqual(episodes.count, 5, "\(impl): Should respect limit")
        }
    }

    func testFindLatestEpisodesOrderedByDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 3", publishedDate: Date(timeIntervalSinceNow: -172800), dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 1", publishedDate: Date(), dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Episode 2", publishedDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager)

            let episodes = dataManager.findLatestEpisodes(podcast: podcast, limit: 3)

            XCTAssertEqual(episodes.count, 3, "\(impl): Should return 3 episodes")
            XCTAssertEqual(episodes[0].title, "Episode 1", "\(impl): First should be most recent")
            XCTAssertEqual(episodes[1].title, "Episode 2", "\(impl): Second should be middle")
            XCTAssertEqual(episodes[2].title, "Episode 3", "\(impl): Third should be oldest")
        }
    }

    // MARK: - downloadedEpisodeCount Tests

    func testDownloadedEpisodeCountReturnsCorrectCount() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            let count = dataManager.downloadedEpisodeCount()

            XCTAssertEqual(count, 2, "\(impl): Should count only downloaded episodes")
        }
    }

    func testDownloadedEpisodeCountReturnsZeroWhenNone() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = dataManager.downloadedEpisodeCount()

            XCTAssertEqual(count, 0, "\(impl): Should return 0 when no downloaded episodes")
        }
    }

    // MARK: - downloadedEpisodeExists Tests

    func testDownloadedEpisodeExistsReturnsTrueWhenExists() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "downloaded-episode", podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            let exists = dataManager.downloadedEpisodeExists(uuid: episode.uuid)

            XCTAssertTrue(exists, "\(impl): Should return true for downloaded episode")
        }
    }

    func testDownloadedEpisodeExistsReturnsFalseWhenNotDownloaded() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            let exists = dataManager.downloadedEpisodeExists(uuid: episode.uuid)

            XCTAssertFalse(exists, "\(impl): Should return false for non-downloaded episode")
        }
    }

    func testDownloadedEpisodeExistsReturnsFalseWhenNotFound() throws {
        try runWithBothImplementations { dataManager, impl in
            let exists = dataManager.downloadedEpisodeExists(uuid: "non-existent")

            XCTAssertFalse(exists, "\(impl): Should return false for non-existent episode")
        }
    }

    // MARK: - unsyncedEpisodes Tests

    func testUnsyncedEpisodesReturnsEpisodesWithModifiedFields() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)

            let episode1 = Episode()
            episode1.uuid = "unsynced-1"
            episode1.podcastUuid = podcast.uuid
            episode1.podcast_id = podcast.id
            episode1.addedDate = Date()
            episode1.playingStatusModified = 1
            dataManager.save(episode: episode1)

            let episode2 = Episode()
            episode2.uuid = "synced"
            episode2.podcastUuid = podcast.uuid
            episode2.podcast_id = podcast.id
            episode2.addedDate = Date()
            episode2.playingStatusModified = 0
            dataManager.save(episode: episode2)

            let unsynced = dataManager.unsyncedEpisodes(limit: 10)

            XCTAssertEqual(unsynced.count, 1, "\(impl): Should return only unsynced episode")
            XCTAssertEqual(unsynced.first?.uuid, "unsynced-1", "\(impl): Should return correct unsynced episode")
        }
    }

    func testUnsyncedEpisodesChecksMultipleModifiedFields() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)

            let episode1 = Episode()
            episode1.uuid = "modified-played"
            episode1.podcastUuid = podcast.uuid
            episode1.podcast_id = podcast.id
            episode1.addedDate = Date()
            episode1.playedUpToModified = 1
            dataManager.save(episode: episode1)

            let episode2 = Episode()
            episode2.uuid = "modified-duration"
            episode2.podcastUuid = podcast.uuid
            episode2.podcast_id = podcast.id
            episode2.addedDate = Date()
            episode2.durationModified = 1
            dataManager.save(episode: episode2)

            let episode3 = Episode()
            episode3.uuid = "modified-archived"
            episode3.podcastUuid = podcast.uuid
            episode3.podcast_id = podcast.id
            episode3.addedDate = Date()
            episode3.archivedModified = 1
            dataManager.save(episode: episode3)

            let unsynced = dataManager.unsyncedEpisodes(limit: 10)

            XCTAssertEqual(unsynced.count, 3, "\(impl): Should detect all modified fields")
        }
    }

    // MARK: - delete Tests

    func testDeleteRemovesEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "to-delete", podcast: podcast, dataManager: dataManager)

            dataManager.delete(episodeUuid: episode.uuid)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertNil(found, "\(impl): Should delete episode")
        }
    }

    // MARK: - deleteAllEpisodesInPodcast Tests

    func testDeleteAllEpisodesInPodcastRemovesAllEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            let initialCount = dataManager.allEpisodesForPodcast(id: podcast.id).count
            XCTAssertEqual(initialCount, 3, "\(impl): Should have 3 episodes initially")

            dataManager.deleteAllEpisodesInPodcast(podcastId: podcast.id)

            let finalCount = dataManager.allEpisodesForPodcast(id: podcast.id).count
            XCTAssertEqual(finalCount, 0, "\(impl): Should have 0 episodes after deletion")
        }
    }

    // MARK: - markAllEpisodePlaybackHistorySynced Tests

    func testMarkAllEpisodePlaybackHistorySyncedUpdatesSyncStatus() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            dataManager.markAllEpisodePlaybackHistorySynced()

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.lastPlaybackInteractionSyncStatus, SyncStatus.synced.rawValue, "\(impl): Should mark as synced")
        }
    }

    // MARK: - failedDownloadedEpisodesCount Tests

    func testFailedDownloadedEpisodesCountReturnsCorrectCount() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.downloadFailed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.downloadFailed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            let count = dataManager.failedDownloadedEpisodesCount()

            XCTAssertEqual(count, 2, "\(impl): Should count only failed download episodes")
        }
    }

    func testFailedDownloadedEpisodesCountReturnsZeroWhenNone() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            let count = dataManager.failedDownloadedEpisodesCount()

            XCTAssertEqual(count, 0, "\(impl): Should return 0 when no failed downloads")
        }
    }

    // MARK: - episodesWithListenHistory Tests

    func testEpisodesWithListenHistoryReturnsEpisodesWithInteractionDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Has History", lastPlaybackInteractionDate: Date(), dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "No History", lastPlaybackInteractionDate: nil, dataManager: dataManager)

            let episodes = dataManager.episodesWithListenHistory(limit: 10)

            XCTAssertEqual(episodes.count, 1, "\(impl): Should return only episodes with listen history")
            XCTAssertEqual(episodes.first?.title, "Has History", "\(impl): Should return correct episode")
        }
    }

    func testEpisodesWithListenHistoryRespectsLimit() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            for i in 0..<10 {
                _ = self.createTestEpisode(podcast: podcast, title: "Episode \(i)", lastPlaybackInteractionDate: Date(timeIntervalSinceNow: Double(-i * 3600)), dataManager: dataManager)
            }

            let episodes = dataManager.episodesWithListenHistory(limit: 5)

            XCTAssertEqual(episodes.count, 5, "\(impl): Should respect limit")
        }
    }

    func testEpisodesWithListenHistoryOrdersByInteractionDateDescending() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let oldDate = Date(timeIntervalSinceNow: -86400)
            let newDate = Date()

            _ = self.createTestEpisode(podcast: podcast, title: "Old", lastPlaybackInteractionDate: oldDate, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "New", lastPlaybackInteractionDate: newDate, dataManager: dataManager)

            let episodes = dataManager.episodesWithListenHistory(limit: 10)

            XCTAssertEqual(episodes.first?.title, "New", "\(impl): Most recent should be first")
            XCTAssertEqual(episodes.last?.title, "Old", "\(impl): Oldest should be last")
        }
    }

    // MARK: - clearEpisodePlaybackInteractionDatesBefore Tests

    func testClearEpisodePlaybackInteractionDatesBeforeClearsOldDates() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let cutoffDate = Date()
            let oldDate = Date(timeIntervalSinceNow: -86400)
            let newDate = Date(timeIntervalSinceNow: 86400)

            let oldEpisode = self.createTestEpisode(uuid: "old-ep", podcast: podcast, lastPlaybackInteractionDate: oldDate, dataManager: dataManager)
            let newEpisode = self.createTestEpisode(uuid: "new-ep", podcast: podcast, lastPlaybackInteractionDate: newDate, dataManager: dataManager)

            dataManager.clearEpisodePlaybackInteractionDatesBefore(date: cutoffDate)

            let foundOld = dataManager.findEpisode(uuid: oldEpisode.uuid)
            let foundNew = dataManager.findEpisode(uuid: newEpisode.uuid)

            XCTAssertNil(foundOld?.lastPlaybackInteractionDate, "\(impl): Old episode should have nil interaction date")
            XCTAssertNotNil(foundNew?.lastPlaybackInteractionDate, "\(impl): New episode should still have interaction date")
        }
    }

    // MARK: - bulkSave Tests

    func testBulkSaveSavesMultipleEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)

            var episodes = [Episode]()
            for i in 0..<5 {
                let episode = Episode()
                episode.uuid = "bulk-\(i)"
                episode.podcastUuid = podcast.uuid
                episode.podcast_id = podcast.id
                episode.title = "Bulk Episode \(i)"
                episode.addedDate = Date()
                episodes.append(episode)
            }

            dataManager.bulkSave(episodes: episodes)

            for i in 0..<5 {
                let found = dataManager.findEpisode(uuid: "bulk-\(i)")
                XCTAssertNotNil(found, "\(impl): Should find bulk saved episode \(i)")
                XCTAssertEqual(found?.title, "Bulk Episode \(i)", "\(impl): Title should match for episode \(i)")
            }
        }
    }

    // MARK: - bulkMarkAsPlayed Tests

    func testBulkMarkAsPlayedMarksEpisodesAsPlayed() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, playingStatus: PlayingStatus.inProgress.rawValue, dataManager: dataManager)

            dataManager.bulkMarkAsPlayed(episodes: [episode1, episode2], updateSyncFlag: false)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertEqual(found1?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Episode 1 should be marked as played")
            XCTAssertEqual(found2?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Episode 2 should be marked as played")
        }
    }

    func testBulkMarkAsPlayedSkipsAlreadyPlayedEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "already-played", podcast: podcast, playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)

            // This should not crash or cause issues
            dataManager.bulkMarkAsPlayed(episodes: [episode], updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Should still be played")
        }
    }

    // MARK: - bulkMarkAsUnPlayed Tests

    func testBulkMarkAsUnPlayedMarksEpisodesAsNotPlayed() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, playingStatus: PlayingStatus.inProgress.rawValue, dataManager: dataManager)

            dataManager.bulkMarkAsUnPlayed(baseEpisodes: [episode1, episode2], updateSyncFlag: false)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertEqual(found1?.playingStatus, PlayingStatus.notPlayed.rawValue, "\(impl): Episode 1 should be marked as not played")
            XCTAssertEqual(found2?.playingStatus, PlayingStatus.notPlayed.rawValue, "\(impl): Episode 2 should be marked as not played")
        }
    }

    func testBulkMarkAsUnPlayedResetsPlayedUpTo() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.inProgress.rawValue, playedUpTo: 300.0, dataManager: dataManager)

            dataManager.bulkMarkAsUnPlayed(baseEpisodes: [episode], updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playedUpTo, 0, "\(impl): playedUpTo should be reset to 0")
        }
    }

    // MARK: - bulkArchive Tests

    func testBulkArchiveArchivesEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, dataManager: dataManager)

            dataManager.bulkArchive(episodes: [episode1, episode2], markAsNotDownloaded: false, markAsPlayed: false, updateSyncFlag: false)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertTrue(found1?.archived ?? false, "\(impl): Episode 1 should be archived")
            XCTAssertTrue(found2?.archived ?? false, "\(impl): Episode 2 should be archived")
        }
    }

    func testBulkArchiveCanMarkAsNotDownloaded() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            dataManager.bulkArchive(episodes: [episode], markAsNotDownloaded: true, markAsPlayed: false, updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.notDownloaded.rawValue, "\(impl): Should mark as not downloaded")
        }
    }

    func testBulkArchiveCanMarkAsPlayed() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            dataManager.bulkArchive(episodes: [episode], markAsNotDownloaded: false, markAsPlayed: true, updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Should mark as played")
        }
    }

    // MARK: - bulkUnarchive Tests

    func testBulkUnarchiveUnarchivesEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: true, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, archived: true, dataManager: dataManager)

            dataManager.bulkUnarchive(episodes: [episode1, episode2], updateSyncFlag: false)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertFalse(found1?.archived ?? true, "\(impl): Episode 1 should be unarchived")
            XCTAssertFalse(found2?.archived ?? true, "\(impl): Episode 2 should be unarchived")
        }
    }

    // MARK: - markAllUnarchivedForPodcast Tests

    func testMarkAllUnarchivedForPodcastUnarchivesAllEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: true, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, archived: true, dataManager: dataManager)

            dataManager.markAllUnarchivedForPodcast(id: podcast.id)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertFalse(found1?.archived ?? true, "\(impl): Episode 1 should be unarchived")
            XCTAssertFalse(found2?.archived ?? true, "\(impl): Episode 2 should be unarchived")
        }
    }

    func testMarkAllUnarchivedForPodcastOnlyAffectsSpecifiedPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast1 = self.createTestPodcast(uuid: "podcast-1", dataManager: dataManager)
            let podcast2 = self.createTestPodcast(uuid: "podcast-2", dataManager: dataManager)

            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast1, archived: true, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast2, archived: true, dataManager: dataManager)

            dataManager.markAllUnarchivedForPodcast(id: podcast1.id)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertFalse(found1?.archived ?? true, "\(impl): Episode in podcast1 should be unarchived")
            XCTAssertTrue(found2?.archived ?? false, "\(impl): Episode in podcast2 should still be archived")
        }
    }

    // MARK: - findEpisodes (search) Tests

    func testFindEpisodesSearchesTitle() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "search-podcast", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Swift Programming Guide", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Python Tutorial", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Advanced Swift Tips", dataManager: dataManager)

            let episodes = dataManager.findEpisodes(with: "Swift", podcastUUID: podcast.uuid)

            XCTAssertEqual(episodes.count, 2, "\(impl): Should find 2 episodes matching Swift")
        }
    }

    func testFindEpisodesIsCaseInsensitive() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "search-podcast", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "SWIFT Programming", dataManager: dataManager)

            let episodes = dataManager.findEpisodes(with: "swift", podcastUUID: podcast.uuid)

            XCTAssertEqual(episodes.count, 1, "\(impl): Should find episode with case-insensitive search")
        }
    }

    func testFindEpisodesExcludesDeletedEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "search-podcast", dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Swift Guide", wasDeleted: false, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, title: "Swift Tips Deleted", wasDeleted: true, dataManager: dataManager)

            let episodes = dataManager.findEpisodes(with: "Swift", podcastUUID: podcast.uuid)

            XCTAssertEqual(episodes.count, 1, "\(impl): Should exclude deleted episodes")
        }
    }

}
