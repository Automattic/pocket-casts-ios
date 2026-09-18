@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import GRDB
import XCTest

/// Tests for PlaylistDataManager using the public API.
final class PlaylistDataManagerTests: DataManagerTestCase {

    // MARK: - Count Tests

    func testPlaylistsCountReturnsZeroWhenNoPlaylists() throws {
        try runWithDataManager { dataManager in
            let count = dataManager.playlistsCount(includeDeleted: false)
            XCTAssertEqual(count, 0, "Should return 0 when no playlists")
        }
    }

    func testPlaylistsCountReturnsCorrectCount() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Playlist 1", dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 3", dataManager: dataManager)

            let count = dataManager.playlistsCount(includeDeleted: false)
            XCTAssertGreaterThanOrEqual(count, 3, "Should count at least 3 playlists")
        }
    }

    func testPlaylistsCountExcludesDeletedWhenNotIncluded() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Active Playlist", dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted Playlist", wasDeleted: true, dataManager: dataManager)

            let count = dataManager.playlistsCount(includeDeleted: false)
            let countWithDeleted = dataManager.playlistsCount(includeDeleted: true)

            XCTAssertLessThan(count, countWithDeleted, "Should exclude deleted when not included")
        }
    }

    // MARK: - findPlaylist Tests

    func testFindPlaylistReturnsPlaylist() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(uuid: "test-playlist-uuid", name: "Test Playlist", dataManager: dataManager)

            let found = dataManager.findPlaylist(uuid: "test-playlist-uuid")

            XCTAssertNotNil(found, "Should find playlist")
            XCTAssertEqual(found?.uuid, playlist.uuid, "UUID should match")
            XCTAssertEqual(found?.playlistName, playlist.playlistName, "Name should match")
        }
    }

    func testFindPlaylistReturnsNilForNonExistent() throws {
        try runWithDataManager { dataManager in
            let found = dataManager.findPlaylist(uuid: "non-existent-uuid")
            XCTAssertNil(found, "Should not find non-existent playlist")
        }
    }

    // MARK: - allPlaylists Tests

    func testAllPlaylistsReturnsAllPlaylists() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Playlist 1", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", sortPosition: 2, dataManager: dataManager)

            let playlists = dataManager.allPlaylists(includeDeleted: false)
            XCTAssertGreaterThanOrEqual(playlists.count, 2, "Should return at least 2 playlists")
        }
    }

    func testAllPlaylistsExcludesDeletedWhenNotIncluded() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Active", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted", sortPosition: 2, wasDeleted: true, dataManager: dataManager)

            let playlists = dataManager.allPlaylists(includeDeleted: false)
            let playlistsWithDeleted = dataManager.allPlaylists(includeDeleted: true)

            XCTAssertLessThan(playlists.count, playlistsWithDeleted.count, "Should exclude deleted when not included")
        }
    }

    func testAllPlaylistsIncludesDeletedWhenRequested() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Active", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted", sortPosition: 2, wasDeleted: true, dataManager: dataManager)

            let playlistsWithDeleted = dataManager.allPlaylists(includeDeleted: true)

            let deletedPlaylist = playlistsWithDeleted.first { $0.playlistName == "Deleted" }
            XCTAssertNotNil(deletedPlaylist, "Should include deleted when requested")
        }
    }

    func testAllPlaylistsOrderedBySortPosition() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Third", sortPosition: 300, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "First", sortPosition: 100, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Second", sortPosition: 200, dataManager: dataManager)

            let playlists = dataManager.allPlaylists(includeDeleted: false)

            // Find our test playlists by name
            let testPlaylists = playlists.filter { ["First", "Second", "Third"].contains($0.playlistName) }

            if testPlaylists.count == 3 {
                XCTAssertEqual(testPlaylists[0].playlistName, "First", "First should be at position 0")
                XCTAssertEqual(testPlaylists[1].playlistName, "Second", "Second should be at position 1")
                XCTAssertEqual(testPlaylists[2].playlistName, "Third", "Third should be at position 2")
            }
        }
    }

    // MARK: - allSmartPlaylists Tests

    func testAllSmartPlaylistsReturnsOnlySmartPlaylists() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Smart 1", manual: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Smart 2", manual: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Manual", manual: true, dataManager: dataManager)

            let playlists = dataManager.allSmartPlaylists(includeDeleted: false)

            XCTAssertTrue(playlists.allSatisfy { $0.manual == false }, "Should only return smart playlists")
        }
    }

    func testAllSmartPlaylistsIncludesDeletedWhenRequested() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Active Smart", manual: false, wasDeleted: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted Smart", manual: false, wasDeleted: true, dataManager: dataManager)

            let playlists = dataManager.allSmartPlaylists(includeDeleted: false)
            let playlistsWithDeleted = dataManager.allSmartPlaylists(includeDeleted: true)

            XCTAssertLessThan(playlists.count, playlistsWithDeleted.count, "Should include deleted when requested")
        }
    }

    // MARK: - allManualPlaylists Tests

    func testAllManualPlaylistsReturnsOnlyManualPlaylists() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Manual 1", manual: true, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Manual 2", manual: true, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Smart", manual: false, dataManager: dataManager)

            let playlists = dataManager.allManualPlaylists(includeDeleted: false)

            XCTAssertTrue(playlists.allSatisfy { $0.manual == true }, "Should only return manual playlists")
        }
    }

    func testAllManualPlaylistsIncludesDeletedWhenRequested() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Active Manual", manual: true, wasDeleted: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted Manual", manual: true, wasDeleted: true, dataManager: dataManager)

            let playlists = dataManager.allManualPlaylists(includeDeleted: false)
            let playlistsWithDeleted = dataManager.allManualPlaylists(includeDeleted: true)

            XCTAssertLessThan(playlists.count, playlistsWithDeleted.count, "Should include deleted when requested")
        }
    }

    // MARK: - allUnsyncedPlaylists Tests

    func testAllUnsyncedPlaylistsReturnsUnsyncedPlaylists() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Unsynced 1", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Unsynced 2", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Synced", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            let playlists = dataManager.allUnsyncedPlaylists()

            XCTAssertTrue(playlists.allSatisfy { $0.syncStatus == SyncStatus.notSynced.rawValue }, "Should only return unsynced playlists")
        }
    }

    // MARK: - playlistContainsEpisode Tests

    func testPlaylistContainsEpisodeReturnsTrueWhenContains() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Test Playlist", manual: true, dataManager: dataManager)
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            _ = dataManager.add(episodes: [episode], to: playlist)

            let contains = dataManager.playlistContainsEpisode(episodeUuid: episode.uuid, includeDeleted: false)

            XCTAssertTrue(contains, "Should return true when playlist contains episode")
        }
    }

    func testPlaylistContainsEpisodeReturnsFalseWhenNotContains() throws {
        try runWithDataManager { dataManager in
            let contains = dataManager.playlistContainsEpisode(episodeUuid: "non-existent-episode", includeDeleted: false)
            XCTAssertFalse(contains, "Should return false when no playlist contains episode")
        }
    }

    // MARK: - nextSortPositionForPlaylist Tests

    func testNextSortPositionForPlaylistReturnsNextPosition() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Playlist 1", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", sortPosition: 5, dataManager: dataManager)

            let nextPosition = dataManager.nextSortPositionForPlaylist()

            XCTAssertEqual(nextPosition, 6, "Should return next position")
        }
    }

    func testNextSortPositionForPlaylistReturnsOneWhenEmpty() throws {
        try runWithDataManager { dataManager in
            let nextPosition = dataManager.nextSortPositionForPlaylist()
            XCTAssertEqual(nextPosition, 1, "Should return 1 when no playlists")
        }
    }

    // MARK: - firstSortPositionForPlaylist Tests

    func testFirstSortPositionForPlaylistReturnsMinPosition() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Playlist 1", sortPosition: 5, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 3", sortPosition: 10, dataManager: dataManager)

            let firstPosition = dataManager.firstSortPositionForPlaylist()

            XCTAssertEqual(firstPosition, 1, "Should return minimum position")
        }
    }

    // MARK: - deleteDeletedPlaylists Tests

    func testDeleteDeletedPlaylistsRemovesDeletedPlaylists() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Active", wasDeleted: false, dataManager: dataManager)
            let deleted = self.createTestPlaylist(name: "Deleted", wasDeleted: true, dataManager: dataManager)

            dataManager.deleteDeletedPlaylists()

            let found = dataManager.findPlaylist(uuid: deleted.uuid)
            XCTAssertNil(found, "Should remove deleted playlist")
        }
    }

    // MARK: - markAllPlaylistsSynced Tests

    func testMarkAllPlaylistsSyncedMarksAllAsSynced() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestPlaylist(name: "Playlist 1", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)

            dataManager.markAllPlaylistsSynced()

            let unsynced = dataManager.allUnsyncedPlaylists()
            XCTAssertTrue(unsynced.isEmpty, "Should have no unsynced playlists")
        }
    }

    // MARK: - markAllPlaylistsUnsynced Tests

    func testMarkAllPlaylistsUnsyncedMarksAllAsUnsynced() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Synced Playlist", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            dataManager.markAllPlaylistsUnsynced()

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "Should mark as unsynced")
        }
    }

    // MARK: - delete Tests

    func testDeleteRemovesPlaylist() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "To Delete", dataManager: dataManager)

            dataManager.delete(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertNil(found, "Should remove playlist")
        }
    }

    // MARK: - deleteAllEpisodes Tests

    func testDeleteAllEpisodesRemovesEpisodesFromPlaylist() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Test Playlist", manual: true, dataManager: dataManager)
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            _ = dataManager.add(episodes: [episode1, episode2], to: playlist)

            dataManager.deleteAllEpisodes(in: playlist)

            let contains1 = dataManager.playlistContainsEpisode(episodeUuid: episode1.uuid, includeDeleted: false)
            let contains2 = dataManager.playlistContainsEpisode(episodeUuid: episode2.uuid, includeDeleted: false)

            XCTAssertFalse(contains1, "Should remove episode 1")
            XCTAssertFalse(contains2, "Should remove episode 2")
        }
    }

    func testDeleteAllEpisodesOnEmptyPlaylistDoesNothing() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Empty Playlist", manual: true, dataManager: dataManager)

            // This should not crash when no episodes to delete
            dataManager.deleteAllEpisodes(in: playlist)

            // Playlist should still exist
            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertNotNil(found, "Playlist should still exist")
        }
    }

    // MARK: - bumpSortPositionForAllPlaylists Tests

    func testBumpSortPositionForAllPlaylistsIncrementsPosition() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Test Playlist", sortPosition: 5, dataManager: dataManager)

            dataManager.bumpSortPositionForAllPlaylists(adding: 10)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.sortPosition, 15, "Should increment position")
        }
    }

    // MARK: - updatePosition Tests

    func testUpdatePositionUpdatesPosition() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Test Playlist", sortPosition: 5, dataManager: dataManager)

            dataManager.updatePosition(playlist: playlist, newPosition: 10)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.sortPosition, 10, "Should update position")
        }
    }

    func testUpdatePositionMarksAsUnsynced() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Test Playlist", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            dataManager.updatePosition(playlist: playlist, newPosition: 10)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "Should mark as unsynced")
        }
    }

    // MARK: - updatePlaylistUpdateDate Tests

    func testUpdatePlaylistUpdateDateUpdatesDate() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(name: "Test Playlist", dataManager: dataManager)
            let newDate = Date(timeIntervalSince1970: 1000000)

            dataManager.updatePlaylistUpdateDate(for: playlist, to: newDate)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertNotNil(found?.playlistUpdateDate, "Should have update date")
        }
    }

    // MARK: - save Tests (PersistableRecord API)

    func testSaveInsertsNewPlaylistWithAllFields() throws {
        try runWithDataManager { dataManager in
            let playlist = EpisodeFilter()
            playlist.uuid = "save-test-uuid"
            playlist.playlistName = "Save Test Playlist"
            playlist.manual = true
            playlist.sortPosition = 99
            playlist.syncStatus = SyncStatus.notSynced.rawValue
            playlist.wasDeleted = false
            playlist.autoDownloadEpisodes = true
            playlist.filterHours = 48
            playlist.filterDuration = true
            playlist.filterUnplayed = true
            playlist.filterPartiallyPlayed = true
            playlist.filterFinished = false
            playlist.filterStarred = true
            playlist.filterAllPodcasts = true

            dataManager.save(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: "save-test-uuid")
            XCTAssertNotNil(found, "Should find saved playlist")
            XCTAssertEqual(found?.uuid, "save-test-uuid", "UUID should match")
            XCTAssertEqual(found?.playlistName, "Save Test Playlist", "Name should match")
            XCTAssertEqual(found?.manual, true, "manual should match")
            XCTAssertEqual(found?.sortPosition, 99, "sortPosition should match")
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "syncStatus should match")
            XCTAssertEqual(found?.wasDeleted, false, "wasDeleted should match")
            XCTAssertEqual(found?.autoDownloadEpisodes, true, "autoDownloadEpisodes should match")
            XCTAssertEqual(found?.filterHours, 48, "filterHours should match")
            XCTAssertEqual(found?.filterDuration, true, "filterDuration should match")
            XCTAssertEqual(found?.filterUnplayed, true, "filterUnplayed should match")
            XCTAssertEqual(found?.filterPartiallyPlayed, true, "filterPartiallyPlayed should match")
            XCTAssertEqual(found?.filterFinished, false, "filterFinished should match")
            XCTAssertEqual(found?.filterStarred, true, "filterStarred should match")
            XCTAssertEqual(found?.filterAllPodcasts, true, "filterAllPodcasts should match")
        }
    }

    func testSaveUpdatesExistingPlaylist() throws {
        try runWithDataManager { dataManager in
            let playlist = self.createTestPlaylist(uuid: "update-test-uuid", name: "Original Name", manual: false, dataManager: dataManager)

            // Update fields
            playlist.playlistName = "Updated Name"
            playlist.manual = true
            playlist.autoDownloadEpisodes = true
            playlist.filterHours = 72
            playlist.syncStatus = SyncStatus.synced.rawValue
            dataManager.save(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: "update-test-uuid")
            XCTAssertEqual(found?.playlistName, "Updated Name", "Name should be updated")
            XCTAssertEqual(found?.manual, true, "manual should be updated")
            XCTAssertEqual(found?.autoDownloadEpisodes, true, "autoDownloadEpisodes should be updated")
            XCTAssertEqual(found?.filterHours, 72, "filterHours should be updated")
            XCTAssertEqual(found?.syncStatus, SyncStatus.synced.rawValue, "syncStatus should be updated")
        }
    }

    func testSaveGeneratesIdIfZero() throws {
        try runWithDataManager { dataManager in
            let playlist = EpisodeFilter()
            playlist.uuid = "id-test-uuid"
            playlist.playlistName = "ID Test Playlist"
            playlist.id = 0

            dataManager.save(playlist: playlist)

            XCTAssertNotEqual(playlist.id, 0, "ID should be generated")

            let found = dataManager.findPlaylist(uuid: "id-test-uuid")
            XCTAssertNotNil(found, "Should find playlist with generated ID")
            XCTAssertNotEqual(found?.id, 0, "Found playlist should have non-zero ID")
        }
    }

    func testSaveUpdatesPlaylistUpdateDate() throws {
        try runWithDataManager { dataManager in
            let playlist = EpisodeFilter()
            playlist.uuid = "date-test-uuid"
            playlist.playlistName = "Date Test Playlist"

            let beforeSave = Date()
            dataManager.save(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: "date-test-uuid")
            XCTAssertNotNil(found?.playlistUpdateDate, "playlistUpdateDate should be set")
            if let updateDate = found?.playlistUpdateDate {
                XCTAssertGreaterThanOrEqual(updateDate, beforeSave.addingTimeInterval(-1), "playlistUpdateDate should be recent")
            }
        }
    }

    func testSavePreservesFilterSettings() throws {
        try runWithDataManager { dataManager in
            let playlist = EpisodeFilter()
            playlist.uuid = "filter-test-uuid"
            playlist.playlistName = "Filter Test Playlist"
            playlist.filterAudioVideoType = 2
            playlist.filterDownloaded = true
            playlist.filterNotDownloaded = true
            playlist.sortType = 3
            playlist.podcastUuids = "podcast-1,podcast-2,podcast-3"

            dataManager.save(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: "filter-test-uuid")
            XCTAssertEqual(found?.filterAudioVideoType, 2, "filterAudioVideoType should be preserved")
            XCTAssertEqual(found?.filterDownloaded, true, "filterDownloaded should be preserved")
            XCTAssertEqual(found?.filterNotDownloaded, true, "filterNotDownloaded should be preserved")
            XCTAssertEqual(found?.sortType, 3, "sortType should be preserved")
            XCTAssertEqual(found?.podcastUuids, "podcast-1,podcast-2,podcast-3", "podcastUuids should be preserved")
        }
    }
}
