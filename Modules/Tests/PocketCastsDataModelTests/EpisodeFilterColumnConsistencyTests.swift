import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class EpisodeFilterColumnConsistencyTests: DataManagerTestCase {

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let tableColumns = try DataManager.newTestDataManager().testDbQueue.dbPool.read { db in
            Set(try db.columns(in: DataManager.playlistsTableName).map(\.name))
        }
        let encodedColumns = Set(try EpisodeFilter().databaseDictionary.keys)

        XCTAssertEqual(
            encodedColumns.subtracting(tableColumns),
            [],
            "EpisodeFilter encodes columns the table doesn't have"
        )
        XCTAssertEqual(
            tableColumns.subtracting(encodedColumns),
            ["filterDownloading"],
            "Table columns that saving an EpisodeFilter doesn't write"
        )
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoadPreservesAllFields() throws {
        try runWithDataManager { dataManager in
            let original = self.createFullyPopulatedEpisodeFilter()

            dataManager.save(playlist: original)

            // Load it back
            guard let loaded = dataManager.findPlaylist(uuid: original.uuid) else {
                XCTFail("Should be able to load saved filter")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "uuid should match")
            XCTAssertEqual(loaded.playlistName, original.playlistName, "playlistName should match")
            XCTAssertEqual(loaded.customIcon, original.customIcon, "customIcon should match")
            XCTAssertEqual(loaded.filterAllPodcasts, original.filterAllPodcasts, "filterAllPodcasts should match")
            XCTAssertEqual(loaded.filterAudioVideoType, original.filterAudioVideoType, "filterAudioVideoType should match")
            XCTAssertEqual(loaded.filterDownloaded, original.filterDownloaded, "filterDownloaded should match")
            XCTAssertEqual(loaded.filterFinished, original.filterFinished, "filterFinished should match")
            XCTAssertEqual(loaded.filterNotDownloaded, original.filterNotDownloaded, "filterNotDownloaded should match")
            XCTAssertEqual(loaded.filterPartiallyPlayed, original.filterPartiallyPlayed, "filterPartiallyPlayed should match")
            XCTAssertEqual(loaded.filterStarred, original.filterStarred, "filterStarred should match")
            XCTAssertEqual(loaded.filterUnplayed, original.filterUnplayed, "filterUnplayed should match")
            XCTAssertEqual(loaded.filterHours, original.filterHours, "filterHours should match")
            XCTAssertEqual(loaded.sortPosition, original.sortPosition, "sortPosition should match")
            XCTAssertEqual(loaded.sortType, original.sortType, "sortType should match")
            XCTAssertEqual(loaded.podcastUuids, original.podcastUuids, "podcastUuids should match")
            XCTAssertEqual(loaded.autoDownloadEpisodes, original.autoDownloadEpisodes, "autoDownloadEpisodes should match")
            XCTAssertEqual(loaded.autoDownloadLimit, original.autoDownloadLimit, "autoDownloadLimit should match")
            XCTAssertEqual(loaded.filterDuration, original.filterDuration, "filterDuration should match")
            XCTAssertEqual(loaded.longerThan, original.longerThan, "longerThan should match")
            XCTAssertEqual(loaded.shorterThan, original.shorterThan, "shorterThan should match")
            XCTAssertEqual(loaded.syncStatus, original.syncStatus, "syncStatus should match")
            XCTAssertEqual(loaded.wasDeleted, original.wasDeleted, "wasDeleted should match")
            XCTAssertEqual(loaded.manual, original.manual, "manual should match")
            XCTAssertEqual(loaded.showArchivedEpisodes, original.showArchivedEpisodes, "showArchivedEpisodes should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that filterDownloading is NOT persisted (marked with @GRDBIgnore)
    func testFilterDownloadingNotPersisted() throws {
        try runWithDataManager { dataManager in
            let filter = EpisodeFilter()
            filter.uuid = UUID().uuidString.lowercased()
            filter.playlistName = "Test Filter"
            // filterDownloading is a let constant set to true, can't change it

            dataManager.save(playlist: filter)

            // Load it back - filterDownloading should always be true (its default)
            guard let loaded = dataManager.findPlaylist(uuid: filter.uuid) else {
                XCTFail("Should find saved filter")
                return
            }

            // filterDownloading should be true (its constant default, not persisted)
            XCTAssertTrue(loaded.filterDownloading, "filterDownloading should always be true")
        }
    }

    /// Verifies that internal tracking properties are NOT persisted (marked with @GRDBIgnore)
    func testInternalTrackingPropertiesNotPersisted() throws {
        try runWithDataManager { dataManager in
            let filter = EpisodeFilter()
            filter.uuid = UUID().uuidString.lowercased()
            filter.playlistName = "Test Filter"
            filter.isNew = true
            filter.podcastSmartRuleApplied = true
            filter.episodesSmartRuleApplied = true
            filter.releaseDateSmartRuleApplied = true
            filter.mediaTypeSmartRuleApplied = true
            filter.downloadStatusSmartRuleApplied = true

            dataManager.save(playlist: filter)

            // Load it back - all internal tracking should be default (false)
            guard let loaded = dataManager.findPlaylist(uuid: filter.uuid) else {
                XCTFail("Should find saved filter")
                return
            }

            // Internal tracking properties should be false (not persisted)
            XCTAssertFalse(loaded.isNew, "isNew should NOT be persisted")
            XCTAssertFalse(loaded.podcastSmartRuleApplied, "podcastSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.episodesSmartRuleApplied, "episodesSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.releaseDateSmartRuleApplied, "releaseDateSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.mediaTypeSmartRuleApplied, "mediaTypeSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.downloadStatusSmartRuleApplied, "downloadStatusSmartRuleApplied should NOT be persisted")
        }
    }

    // MARK: - Helpers

    private func createFullyPopulatedEpisodeFilter() -> EpisodeFilter {
        let filter = EpisodeFilter()
        filter.uuid = UUID().uuidString.lowercased()
        filter.playlistName = "Test Filter"
        filter.customIcon = 3
        filter.filterAllPodcasts = true
        filter.filterAudioVideoType = 1
        filter.filterDownloaded = true
        filter.filterFinished = true
        filter.filterNotDownloaded = false
        filter.filterPartiallyPlayed = true
        filter.filterStarred = true
        filter.filterUnplayed = false
        filter.filterHours = 24
        filter.sortPosition = 5
        filter.sortType = 2
        filter.podcastUuids = "uuid1,uuid2,uuid3"
        filter.autoDownloadEpisodes = true
        filter.autoDownloadLimit = 10
        filter.filterDuration = true
        filter.longerThan = 300
        filter.shorterThan = 3600
        filter.syncStatus = SyncStatus.synced.rawValue
        filter.wasDeleted = false
        filter.manual = false
        filter.showArchivedEpisodes = true
        filter.playlistUpdateDate = Date()
        return filter
    }
}
