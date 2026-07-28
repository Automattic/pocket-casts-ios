@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import GRDB
import XCTest

/// Tests for PlaylistDataManager using the public API.
/// These tests run with both SQL and GRDB implementations.
final class PlaylistDataManagerTests: DataManagerTestCase {

    // MARK: - Count Tests

    func testPlaylistsCountReturnsZeroWhenNoPlaylists() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = dataManager.playlistsCount(includeDeleted: false)
            XCTAssertEqual(count, 0, "\(impl): Should return 0 when no playlists")
        }
    }

    func testPlaylistsCountReturnsCorrectCount() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Playlist 1", dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 3", dataManager: dataManager)

            let count = dataManager.playlistsCount(includeDeleted: false)
            XCTAssertGreaterThanOrEqual(count, 3, "\(impl): Should count at least 3 playlists")
        }
    }

    func testPlaylistsCountExcludesDeletedWhenNotIncluded() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Active Playlist", dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted Playlist", wasDeleted: true, dataManager: dataManager)

            let count = dataManager.playlistsCount(includeDeleted: false)
            let countWithDeleted = dataManager.playlistsCount(includeDeleted: true)

            XCTAssertLessThan(count, countWithDeleted, "\(impl): Should exclude deleted when not included")
        }
    }

    // MARK: - findPlaylist Tests

    func testFindPlaylistReturnsPlaylist() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(uuid: "test-playlist-uuid", name: "Test Playlist", dataManager: dataManager)

            let found = dataManager.findPlaylist(uuid: "test-playlist-uuid")

            XCTAssertNotNil(found, "\(impl): Should find playlist")
            XCTAssertEqual(found?.uuid, playlist.uuid, "\(impl): UUID should match")
            XCTAssertEqual(found?.playlistName, playlist.playlistName, "\(impl): Name should match")
        }
    }

    func testFindPlaylistReturnsNilForNonExistent() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.findPlaylist(uuid: "non-existent-uuid")
            XCTAssertNil(found, "\(impl): Should not find non-existent playlist")
        }
    }

    // MARK: - allPlaylists Tests

    func testAllPlaylistsReturnsAllPlaylists() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Playlist 1", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", sortPosition: 2, dataManager: dataManager)

            let playlists = dataManager.allPlaylists(includeDeleted: false)
            XCTAssertGreaterThanOrEqual(playlists.count, 2, "\(impl): Should return at least 2 playlists")
        }
    }

    func testAllPlaylistsExcludesDeletedWhenNotIncluded() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Active", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted", sortPosition: 2, wasDeleted: true, dataManager: dataManager)

            let playlists = dataManager.allPlaylists(includeDeleted: false)
            let playlistsWithDeleted = dataManager.allPlaylists(includeDeleted: true)

            XCTAssertLessThan(playlists.count, playlistsWithDeleted.count, "\(impl): Should exclude deleted when not included")
        }
    }

    func testAllPlaylistsIncludesDeletedWhenRequested() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Active", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted", sortPosition: 2, wasDeleted: true, dataManager: dataManager)

            let playlistsWithDeleted = dataManager.allPlaylists(includeDeleted: true)

            let deletedPlaylist = playlistsWithDeleted.first { $0.playlistName == "Deleted" }
            XCTAssertNotNil(deletedPlaylist, "\(impl): Should include deleted when requested")
        }
    }

    func testAllPlaylistsOrderedBySortPosition() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Third", sortPosition: 300, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "First", sortPosition: 100, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Second", sortPosition: 200, dataManager: dataManager)

            let playlists = dataManager.allPlaylists(includeDeleted: false)

            // Find our test playlists by name
            let testPlaylists = playlists.filter { ["First", "Second", "Third"].contains($0.playlistName) }

            if testPlaylists.count == 3 {
                XCTAssertEqual(testPlaylists[0].playlistName, "First", "\(impl): First should be at position 0")
                XCTAssertEqual(testPlaylists[1].playlistName, "Second", "\(impl): Second should be at position 1")
                XCTAssertEqual(testPlaylists[2].playlistName, "Third", "\(impl): Third should be at position 2")
            }
        }
    }

    // MARK: - allSmartPlaylists Tests

    func testAllSmartPlaylistsReturnsOnlySmartPlaylists() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Smart 1", manual: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Smart 2", manual: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Manual", manual: true, dataManager: dataManager)

            let playlists = dataManager.allSmartPlaylists(includeDeleted: false)

            XCTAssertTrue(playlists.allSatisfy { $0.manual == false }, "\(impl): Should only return smart playlists")
        }
    }

    func testAllSmartPlaylistsIncludesDeletedWhenRequested() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Active Smart", manual: false, wasDeleted: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted Smart", manual: false, wasDeleted: true, dataManager: dataManager)

            let playlists = dataManager.allSmartPlaylists(includeDeleted: false)
            let playlistsWithDeleted = dataManager.allSmartPlaylists(includeDeleted: true)

            XCTAssertLessThan(playlists.count, playlistsWithDeleted.count, "\(impl): Should include deleted when requested")
        }
    }

    // MARK: - allManualPlaylists Tests

    func testAllManualPlaylistsReturnsOnlyManualPlaylists() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Manual 1", manual: true, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Manual 2", manual: true, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Smart", manual: false, dataManager: dataManager)

            let playlists = dataManager.allManualPlaylists(includeDeleted: false)

            XCTAssertTrue(playlists.allSatisfy { $0.manual == true }, "\(impl): Should only return manual playlists")
        }
    }

    func testAllManualPlaylistsIncludesDeletedWhenRequested() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Active Manual", manual: true, wasDeleted: false, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Deleted Manual", manual: true, wasDeleted: true, dataManager: dataManager)

            let playlists = dataManager.allManualPlaylists(includeDeleted: false)
            let playlistsWithDeleted = dataManager.allManualPlaylists(includeDeleted: true)

            XCTAssertLessThan(playlists.count, playlistsWithDeleted.count, "\(impl): Should include deleted when requested")
        }
    }

    // MARK: - allUnsyncedPlaylists Tests

    func testAllUnsyncedPlaylistsReturnsUnsyncedPlaylists() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Unsynced 1", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Unsynced 2", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Synced", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            let playlists = dataManager.allUnsyncedPlaylists()

            XCTAssertTrue(playlists.allSatisfy { $0.syncStatus == SyncStatus.notSynced.rawValue }, "\(impl): Should only return unsynced playlists")
        }
    }

    // MARK: - playlistContainsEpisode Tests

    func testPlaylistContainsEpisodeReturnsTrueWhenContains() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Test Playlist", manual: true, dataManager: dataManager)
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            _ = dataManager.add(episodes: [episode], to: playlist)

            let contains = dataManager.playlistContainsEpisode(episodeUuid: episode.uuid, includeDeleted: false)

            XCTAssertTrue(contains, "\(impl): Should return true when playlist contains episode")
        }
    }

    func testPlaylistContainsEpisodeReturnsFalseWhenNotContains() throws {
        try runWithBothImplementations { dataManager, impl in
            let contains = dataManager.playlistContainsEpisode(episodeUuid: "non-existent-episode", includeDeleted: false)
            XCTAssertFalse(contains, "\(impl): Should return false when no playlist contains episode")
        }
    }

    // MARK: - nextSortPositionForPlaylist Tests

    func testNextSortPositionForPlaylistReturnsNextPosition() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Playlist 1", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", sortPosition: 5, dataManager: dataManager)

            let nextPosition = dataManager.nextSortPositionForPlaylist()

            XCTAssertEqual(nextPosition, 6, "\(impl): Should return next position")
        }
    }

    func testNextSortPositionForPlaylistReturnsOneWhenEmpty() throws {
        try runWithBothImplementations { dataManager, impl in
            let nextPosition = dataManager.nextSortPositionForPlaylist()
            XCTAssertEqual(nextPosition, 1, "\(impl): Should return 1 when no playlists")
        }
    }

    // MARK: - firstSortPositionForPlaylist Tests

    func testFirstSortPositionForPlaylistReturnsMinPosition() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Playlist 1", sortPosition: 5, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", sortPosition: 1, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 3", sortPosition: 10, dataManager: dataManager)

            let firstPosition = dataManager.firstSortPositionForPlaylist()

            XCTAssertEqual(firstPosition, 1, "\(impl): Should return minimum position")
        }
    }

    // MARK: - deleteDeletedPlaylists Tests

    func testDeleteDeletedPlaylistsRemovesDeletedPlaylists() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Active", wasDeleted: false, dataManager: dataManager)
            let deleted = self.createTestPlaylist(name: "Deleted", wasDeleted: true, dataManager: dataManager)

            dataManager.deleteDeletedPlaylists()

            let found = dataManager.findPlaylist(uuid: deleted.uuid)
            XCTAssertNil(found, "\(impl): Should remove deleted playlist")
        }
    }

    // MARK: - markAllPlaylistsSynced Tests

    func testMarkAllPlaylistsSyncedMarksAllAsSynced() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPlaylist(name: "Playlist 1", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPlaylist(name: "Playlist 2", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)

            dataManager.markAllPlaylistsSynced()

            let unsynced = dataManager.allUnsyncedPlaylists()
            XCTAssertTrue(unsynced.isEmpty, "\(impl): Should have no unsynced playlists")
        }
    }

    // MARK: - markAllPlaylistsUnsynced Tests

    func testMarkAllPlaylistsUnsyncedMarksAllAsUnsynced() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Synced Playlist", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            dataManager.markAllPlaylistsUnsynced()

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): Should mark as unsynced")
        }
    }

    // MARK: - delete Tests

    func testDeleteRemovesPlaylist() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "To Delete", dataManager: dataManager)

            dataManager.delete(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertNil(found, "\(impl): Should remove playlist")
        }
    }

    // MARK: - deleteAllEpisodes Tests

    func testDeleteAllEpisodesRemovesEpisodesFromPlaylist() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Test Playlist", manual: true, dataManager: dataManager)
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            _ = dataManager.add(episodes: [episode1, episode2], to: playlist)

            dataManager.deleteAllEpisodes(in: playlist)

            let contains1 = dataManager.playlistContainsEpisode(episodeUuid: episode1.uuid, includeDeleted: false)
            let contains2 = dataManager.playlistContainsEpisode(episodeUuid: episode2.uuid, includeDeleted: false)

            XCTAssertFalse(contains1, "\(impl): Should remove episode 1")
            XCTAssertFalse(contains2, "\(impl): Should remove episode 2")
        }
    }

    func testDeleteAllEpisodesOnEmptyPlaylistDoesNothing() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Empty Playlist", manual: true, dataManager: dataManager)

            // This should not crash when no episodes to delete
            dataManager.deleteAllEpisodes(in: playlist)

            // Playlist should still exist
            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertNotNil(found, "\(impl): Playlist should still exist")
        }
    }

    // MARK: - bumpSortPositionForAllPlaylists Tests

    func testBumpSortPositionForAllPlaylistsIncrementsPosition() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Test Playlist", sortPosition: 5, dataManager: dataManager)

            dataManager.bumpSortPositionForAllPlaylists(adding: 10)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.sortPosition, 15, "\(impl): Should increment position")
        }
    }

    // MARK: - updatePosition Tests

    func testUpdatePositionUpdatesPosition() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Test Playlist", sortPosition: 5, dataManager: dataManager)

            dataManager.updatePosition(playlist: playlist, newPosition: 10)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.sortPosition, 10, "\(impl): Should update position")
        }
    }

    func testUpdatePositionMarksAsUnsynced() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Test Playlist", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            dataManager.updatePosition(playlist: playlist, newPosition: 10)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): Should mark as unsynced")
        }
    }

    // MARK: - updatePlaylistUpdateDate Tests

    func testUpdatePlaylistUpdateDateUpdatesDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(name: "Test Playlist", dataManager: dataManager)
            let newDate = Date(timeIntervalSince1970: 1000000)

            dataManager.updatePlaylistUpdateDate(for: playlist, to: newDate)

            let found = dataManager.findPlaylist(uuid: playlist.uuid)
            XCTAssertNotNil(found?.playlistUpdateDate, "\(impl): Should have update date")
        }
    }

    // MARK: - save Tests (PersistableRecord API)

    func testSaveInsertsNewPlaylistWithAllFields() throws {
        try runWithBothImplementations { dataManager, impl in
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
            XCTAssertNotNil(found, "\(impl): Should find saved playlist")
            XCTAssertEqual(found?.uuid, "save-test-uuid", "\(impl): UUID should match")
            XCTAssertEqual(found?.playlistName, "Save Test Playlist", "\(impl): Name should match")
            XCTAssertEqual(found?.manual, true, "\(impl): manual should match")
            XCTAssertEqual(found?.sortPosition, 99, "\(impl): sortPosition should match")
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): syncStatus should match")
            XCTAssertEqual(found?.wasDeleted, false, "\(impl): wasDeleted should match")
            XCTAssertEqual(found?.autoDownloadEpisodes, true, "\(impl): autoDownloadEpisodes should match")
            XCTAssertEqual(found?.filterHours, 48, "\(impl): filterHours should match")
            XCTAssertEqual(found?.filterDuration, true, "\(impl): filterDuration should match")
            XCTAssertEqual(found?.filterUnplayed, true, "\(impl): filterUnplayed should match")
            XCTAssertEqual(found?.filterPartiallyPlayed, true, "\(impl): filterPartiallyPlayed should match")
            XCTAssertEqual(found?.filterFinished, false, "\(impl): filterFinished should match")
            XCTAssertEqual(found?.filterStarred, true, "\(impl): filterStarred should match")
            XCTAssertEqual(found?.filterAllPodcasts, true, "\(impl): filterAllPodcasts should match")
        }
    }

    func testSaveUpdatesExistingPlaylist() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = self.createTestPlaylist(uuid: "update-test-uuid", name: "Original Name", manual: false, dataManager: dataManager)

            // Update fields
            playlist.playlistName = "Updated Name"
            playlist.manual = true
            playlist.autoDownloadEpisodes = true
            playlist.filterHours = 72
            playlist.syncStatus = SyncStatus.synced.rawValue
            dataManager.save(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: "update-test-uuid")
            XCTAssertEqual(found?.playlistName, "Updated Name", "\(impl): Name should be updated")
            XCTAssertEqual(found?.manual, true, "\(impl): manual should be updated")
            XCTAssertEqual(found?.autoDownloadEpisodes, true, "\(impl): autoDownloadEpisodes should be updated")
            XCTAssertEqual(found?.filterHours, 72, "\(impl): filterHours should be updated")
            XCTAssertEqual(found?.syncStatus, SyncStatus.synced.rawValue, "\(impl): syncStatus should be updated")
        }
    }

    func testSaveGeneratesIdIfZero() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = EpisodeFilter()
            playlist.uuid = "id-test-uuid"
            playlist.playlistName = "ID Test Playlist"
            playlist.id = 0

            dataManager.save(playlist: playlist)

            XCTAssertNotEqual(playlist.id, 0, "\(impl): ID should be generated")

            let found = dataManager.findPlaylist(uuid: "id-test-uuid")
            XCTAssertNotNil(found, "\(impl): Should find playlist with generated ID")
            XCTAssertNotEqual(found?.id, 0, "\(impl): Found playlist should have non-zero ID")
        }
    }

    func testSaveUpdatesPlaylistUpdateDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = EpisodeFilter()
            playlist.uuid = "date-test-uuid"
            playlist.playlistName = "Date Test Playlist"

            let beforeSave = Date()
            dataManager.save(playlist: playlist)

            let found = dataManager.findPlaylist(uuid: "date-test-uuid")
            XCTAssertNotNil(found?.playlistUpdateDate, "\(impl): playlistUpdateDate should be set")
            if let updateDate = found?.playlistUpdateDate {
                XCTAssertGreaterThanOrEqual(updateDate, beforeSave.addingTimeInterval(-1), "\(impl): playlistUpdateDate should be recent")
            }
        }
    }

    func testSavePreservesFilterSettings() throws {
        try runWithBothImplementations { dataManager, impl in
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
            XCTAssertEqual(found?.filterAudioVideoType, 2, "\(impl): filterAudioVideoType should be preserved")
            XCTAssertEqual(found?.filterDownloaded, true, "\(impl): filterDownloaded should be preserved")
            XCTAssertEqual(found?.filterNotDownloaded, true, "\(impl): filterNotDownloaded should be preserved")
            XCTAssertEqual(found?.sortType, 3, "\(impl): sortType should be preserved")
            XCTAssertEqual(found?.podcastUuids, "podcast-1,podcast-2,podcast-3", "\(impl): podcastUuids should be preserved")
        }
    }
}
