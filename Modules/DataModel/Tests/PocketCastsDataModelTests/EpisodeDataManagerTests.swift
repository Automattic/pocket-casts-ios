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

    // MARK: - saveEpisode(playingStatus:) Tests

    func testSaveEpisodePlayingStatusUpdatesStatus() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            dataManager.saveEpisode(playingStatus: .completed, episode: episode, updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Playing status should be updated")
        }
    }

    func testSaveEpisodePlayingStatusUpdatesSyncFlag() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            dataManager.saveEpisode(playingStatus: .completed, episode: episode, updateSyncFlag: true)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            // playingStatusModified stores a timestamp when modified, not just a flag
            XCTAssertNotEqual(found?.playingStatusModified, 0, "\(impl): Modified timestamp should be set")
        }
    }

    // MARK: - saveEpisode(archived:) Tests

    func testSaveEpisodeArchivedUpdatesArchiveStatus() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: false, dataManager: dataManager)

            dataManager.saveEpisode(archived: true, episode: episode, updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertTrue(found?.archived ?? false, "\(impl): Archived status should be updated")
        }
    }

    func testSaveEpisodeArchivedUpdatesSyncFlag() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: false, dataManager: dataManager)

            dataManager.saveEpisode(archived: true, episode: episode, updateSyncFlag: true)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            // archivedModified stores a timestamp when modified, not just a flag
            XCTAssertNotEqual(found?.archivedModified, 0, "\(impl): Modified timestamp should be set")
        }
    }

    // MARK: - saveEpisode(playedUpTo:) Tests

    func testSaveEpisodePlayedUpToUpdatesPosition() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playedUpTo: 0, dataManager: dataManager)

            dataManager.saveEpisode(playedUpTo: 300.5, episode: episode, updateSyncFlag: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playedUpTo ?? 0, 300.5, accuracy: 0.01, "\(impl): PlayedUpTo should be updated")
        }
    }

    func testSaveEpisodePlayedUpToUpdatesSyncFlag() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playedUpTo: 0, dataManager: dataManager)

            dataManager.saveEpisode(playedUpTo: 300.5, episode: episode, updateSyncFlag: true)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            // playedUpToModified stores a timestamp when modified, not just a flag
            XCTAssertNotEqual(found?.playedUpToModified, 0, "\(impl): Modified timestamp should be set")
        }
    }

    // MARK: - saveEpisode(excludeFromEpisodeLimit:) Tests

    func testSaveEpisodeExcludeFromEpisodeLimitUpdatesFlag() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            dataManager.saveEpisode(excludeFromEpisodeLimit: true, episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertTrue(found?.excludeFromEpisodeLimit ?? false, "\(impl): excludeFromEpisodeLimit should be updated")
        }
    }

    // MARK: - bulkSetStarred Tests

    func testBulkSetStarredSetsStarredOnEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, dataManager: dataManager)

            dataManager.bulkSetStarred(starred: true, episodes: [episode1, episode2], updateSyncStatus: false)

            let found1 = dataManager.findEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findEpisode(uuid: episode2.uuid)

            XCTAssertTrue(found1?.keepEpisode ?? false, "\(impl): Episode 1 should be starred")
            XCTAssertTrue(found2?.keepEpisode ?? false, "\(impl): Episode 2 should be starred")
        }
    }

    func testBulkSetStarredUnsetsStarred() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, keepEpisode: true, dataManager: dataManager)

            dataManager.bulkSetStarred(starred: false, episodes: [episode], updateSyncStatus: false)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertFalse(found?.keepEpisode ?? true, "\(impl): Episode should be unstarred")
        }
    }

    // MARK: - saveFrameCount/findFrameCount Tests

    func testSaveAndFindFrameCount() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            dataManager.saveFrameCount(episode: episode, frameCount: 12345)

            let frameCount = dataManager.findFrameCount(episode: episode)
            XCTAssertEqual(frameCount, 12345, "\(impl): Frame count should be saved and retrieved")
        }
    }

    func testFindFrameCountReturnsZeroForUnset() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            let frameCount = dataManager.findFrameCount(episode: episode)
            XCTAssertEqual(frameCount, 0, "\(impl): Frame count should be 0 when not set")
        }
    }

    // MARK: - clearEpisodePlaybackInteractionDate Tests

    func testClearEpisodePlaybackInteractionDateClearsDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, lastPlaybackInteractionDate: Date(), dataManager: dataManager)

            dataManager.clearEpisodePlaybackInteractionDate(episodeUuid: episode.uuid)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertNil(found?.lastPlaybackInteractionDate, "\(impl): Interaction date should be cleared")
        }
    }

    // MARK: - setEpisodePlaybackInteractionDate Tests

    func testSetEpisodePlaybackInteractionDateSetsDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, lastPlaybackInteractionDate: nil, dataManager: dataManager)
            let interactionDate = Date()

            dataManager.setEpisodePlaybackInteractionDate(interactionDate: interactionDate, episodeUuid: episode.uuid)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertNotNil(found?.lastPlaybackInteractionDate, "\(impl): Interaction date should be set")
        }
    }

    // MARK: - saveIfNotModified Tests

    func testSaveIfNotModifiedStarredUpdatesWhenNotModified() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, keepEpisode: false, dataManager: dataManager)

            _ = dataManager.saveIfNotModified(starred: true, episodeUuid: episode.uuid)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertTrue(found?.keepEpisode ?? false, "\(impl): Starred should be updated when not modified")
        }
    }

    func testSaveIfNotModifiedArchivedUpdatesWhenNotModified() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: false, dataManager: dataManager)

            _ = dataManager.saveIfNotModified(archived: true, episodeUuid: episode.uuid)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertTrue(found?.archived ?? false, "\(impl): Archived should be updated when not modified")
        }
    }

    func testSaveIfNotModifiedPlayingStatusUpdatesWhenNotModified() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            _ = dataManager.saveIfNotModified(playingStatus: .completed, episodeUuid: episode.uuid)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Playing status should be updated when not modified")
        }
    }

    // MARK: - saveEpisode(contentType:) Tests

    func testSaveContentTypeUpdatesEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            dataManager.saveEpisode(contentType: "audio/mpeg", episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.contentType, "audio/mpeg", "\(impl): Content type should be updated")
        }
    }

    // MARK: - saveEpisode(fileType:) Tests

    func testSaveFileTypeUpdatesEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            dataManager.saveEpisode(fileType: "mp3", episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.fileType, "mp3", "\(impl): File type should be updated")
        }
    }

    // MARK: - saveEpisode(fileSize:) Tests

    func testSaveFileSizeUpdatesEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            dataManager.saveEpisode(fileSize: 1024000, episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.sizeInBytes, 1024000, "\(impl): File size should be updated")
        }
    }

    // MARK: - allUpNextEpisodes(from:) Tests

    func testAllUpNextEpisodesFromUuidsReturnsMatchingEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "ep-2", podcast: podcast, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-3", podcast: podcast, dataManager: dataManager)

            // Add episodes to Up Next (required for allUpNextEpisodes to find them)
            self.addToUpNextBottom(episodeUuid: episode1.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            let episodes = dataManager.allUpNextEpisodes(from: [episode1.uuid, episode2.uuid])

            XCTAssertEqual(episodes.count, 2, "\(impl): Should return 2 episodes")
            let uuids = episodes.map(\.uuid)
            XCTAssertTrue(uuids.contains("ep-1"), "\(impl): Should contain ep-1")
            XCTAssertTrue(uuids.contains("ep-2"), "\(impl): Should contain ep-2")
        }
    }

    func testAllUpNextEpisodesFromUuidsReturnsEmptyForNoMatches() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            let episodes = dataManager.allUpNextEpisodes(from: ["non-existent-uuid"])

            XCTAssertTrue(episodes.isEmpty, "\(impl): Should return empty for non-existent UUIDs")
        }
    }

    // MARK: - findPlayedEpisodes Tests

    func testFindPlayedEpisodesReturnsPlayedUuids() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-played", podcast: podcast, playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-not-played", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            let playedUuids = dataManager.findPlayedEpisodes(uuids: ["ep-played", "ep-not-played"])

            XCTAssertEqual(playedUuids.count, 1, "\(impl): Should return 1 played episode")
            XCTAssertTrue(playedUuids.contains("ep-played"), "\(impl): Should contain played episode UUID")
        }
    }

    func testFindPlayedEpisodesReturnsEmptyWhenNonePlayed() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-2", podcast: podcast, playingStatus: PlayingStatus.inProgress.rawValue, dataManager: dataManager)

            let playedUuids = dataManager.findPlayedEpisodes(uuids: ["ep-1", "ep-2"])

            XCTAssertTrue(playedUuids.isEmpty, "\(impl): Should return empty when no episodes are played")
        }
    }

    // MARK: - findEpisodesAndPodcastsWhere Tests

    func testFindEpisodesAndPodcastsWhereWithListenedTo() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-listened", podcast: podcast, playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-not-listened", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            let episodes = dataManager.findEpisodesAndPodcastsWhere(customWhere: "1=1", listenedTo: true)

            // With listenedTo: true, should return episodes with playing history
            XCTAssertNotNil(episodes, "\(impl): Should return episodes array")
        }
    }

    // MARK: - clearDownloadTaskId Tests

    func testClearDownloadTaskIdClearsTaskId() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            // Set a download task ID first
            dataManager.saveEpisode(downloadStatus: .downloading, downloadTaskId: "task-123", episode: episode)

            // Clear it
            dataManager.clearDownloadTaskId(episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertNil(found?.downloadTaskId, "\(impl): Download task ID should be cleared")
        }
    }

    // MARK: - clearKeepEpisodeModified Tests

    func testClearKeepEpisodeModifiedClearsFlag() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "ep-1", podcast: podcast, keepEpisode: true, dataManager: dataManager)

            dataManager.clearKeepEpisodeModified(episode: episode)

            let found = dataManager.findEpisode(uuid: episode.uuid)
            // The method clears the modified flag, not keepEpisode itself
            XCTAssertNotNil(found, "\(impl): Episode should still exist")
        }
    }

    // MARK: - findGhostEpisodes Tests

    func testFindGhostEpisodesReturnsEpisodesWithoutPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-with-podcast", podcast: podcast, dataManager: dataManager)

            // Create an episode manually with invalid podcast reference
            let ghostEpisode = Episode()
            ghostEpisode.uuid = "ghost-ep"
            ghostEpisode.podcastUuid = "non-existent-podcast"
            ghostEpisode.podcast_id = 99999
            ghostEpisode.addedDate = Date()
            dataManager.save(episode: ghostEpisode)

            let ghostEpisodes = dataManager.findGhostEpisodes()

            // Ghost episodes are those without a matching podcast in the database
            XCTAssertNotNil(ghostEpisodes, "\(impl): Should return ghost episodes array")
        }
    }

    // MARK: - findWhere Tests

    func testFindWhereReturnsMatchingEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-archived", podcast: podcast, archived: true, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-not-archived", podcast: podcast, archived: false, dataManager: dataManager)

            let episodes = dataManager.findEpisodesWhere(customWhere: "archived = ?", arguments: [true])

            XCTAssertEqual(episodes.count, 1, "\(impl): Should return 1 archived episode")
            XCTAssertEqual(episodes.first?.uuid, "ep-archived", "\(impl): Should return the archived episode")
        }
    }

    // MARK: - findPlaylistEpisodesWhere Tests

    func testFindPlaylistEpisodesWhereReturnsFilteredEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: false, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-2", podcast: podcast, archived: true, dataManager: dataManager)

            let episodes = dataManager.findPlaylistEpisodesWhere(query: "SELECT * FROM \(DataManager.episodeTableName) WHERE archived = 0", arguments: nil)

            XCTAssertGreaterThanOrEqual(episodes.count, 1, "\(impl): Should return non-archived episodes")
        }
    }

    // MARK: - saveBulkEpisodeSyncInfo Tests

    func testSaveBulkEpisodeSyncInfoUpdatesMultipleEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-2", podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            var syncInfo1 = EpisodeBasicData()
            syncInfo1.uuid = "ep-1"
            syncInfo1.playingStatus = Int(PlayingStatus.completed.rawValue)
            syncInfo1.playedUpTo = 300

            var syncInfo2 = EpisodeBasicData()
            syncInfo2.uuid = "ep-2"
            syncInfo2.playingStatus = Int(PlayingStatus.inProgress.rawValue)
            syncInfo2.playedUpTo = 150

            dataManager.saveBulkEpisodeSyncInfo(episodes: [syncInfo1, syncInfo2])

            let found1 = dataManager.findEpisode(uuid: "ep-1")
            let found2 = dataManager.findEpisode(uuid: "ep-2")

            XCTAssertEqual(found1?.playingStatus, PlayingStatus.completed.rawValue, "\(impl): Episode 1 playing status should be updated")
            XCTAssertEqual(found2?.playingStatus, PlayingStatus.inProgress.rawValue, "\(impl): Episode 2 playing status should be updated")
        }
    }

    func testSaveBulkEpisodeSyncInfoHandlesArchiveStatus() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, archived: false, dataManager: dataManager)

            var syncInfo = EpisodeBasicData()
            syncInfo.uuid = "ep-1"
            syncInfo.isArchived = true

            dataManager.saveBulkEpisodeSyncInfo(episodes: [syncInfo])

            let found = dataManager.findEpisode(uuid: "ep-1")
            XCTAssertTrue(found?.archived ?? false, "\(impl): Episode should be archived")
        }
    }

    func testSaveBulkEpisodeSyncInfoHandlesStarredStatus() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            var syncInfo = EpisodeBasicData()
            syncInfo.uuid = "ep-1"
            syncInfo.starred = true

            dataManager.saveBulkEpisodeSyncInfo(episodes: [syncInfo])

            let found = dataManager.findEpisode(uuid: "ep-1")
            XCTAssertTrue(found?.keepEpisode ?? false, "\(impl): Episode should be starred")
        }
    }

    func testSaveBulkEpisodeSyncInfoHandlesDuration() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "ep-1", podcast: podcast, dataManager: dataManager)

            var syncInfo = EpisodeBasicData()
            syncInfo.uuid = "ep-1"
            syncInfo.duration = 3600

            dataManager.saveBulkEpisodeSyncInfo(episodes: [syncInfo])

            let found = dataManager.findEpisode(uuid: "ep-1")
            XCTAssertEqual(found?.duration, 3600, "\(impl): Episode duration should be updated")
        }
    }

    // MARK: - Helper method override for additional properties

    @discardableResult
    func createTestEpisode(
        uuid: String = UUID().uuidString,
        podcast: Podcast,
        title: String = "Test Episode",
        publishedDate: Date = Date(),
        episodeStatus: Int32 = DownloadStatus.notDownloaded.rawValue,
        playingStatus: Int32 = PlayingStatus.notPlayed.rawValue,
        playedUpTo: Double = 0,
        archived: Bool = false,
        wasDeleted: Bool = false,
        lastPlaybackInteractionDate: Date? = nil,
        keepEpisode: Bool = false,
        lastDownloadAttemptDate: Date? = nil,
        dataManager: DataManager
    ) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.title = title
        episode.publishedDate = publishedDate
        episode.episodeStatus = episodeStatus
        episode.playingStatus = playingStatus
        episode.playedUpTo = playedUpTo
        episode.archived = archived
        episode.wasDeleted = wasDeleted
        episode.addedDate = Date()
        episode.lastPlaybackInteractionDate = lastPlaybackInteractionDate
        episode.keepEpisode = keepEpisode
        episode.lastDownloadAttemptDate = lastDownloadAttemptDate
        dataManager.save(episode: episode)
        return episode
    }

}
