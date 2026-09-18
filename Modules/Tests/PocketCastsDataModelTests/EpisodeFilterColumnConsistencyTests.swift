import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests to ensure the legacy SQL columnNames and GRDB-persisted columns remain in sync.
/// These tests prevent the issue where GRDB might persist a field that the legacy SQL path ignores
/// (or vice versa), causing inconsistent behavior when the feature flag is toggled.
final class EpisodeFilterColumnConsistencyTests: DataManagerTestCase {

    /// Access columnNames directly from PlaylistDataManager (the source of truth for legacy SQL).
    private var columnNames: Set<String> {
        Set(PlaylistDataManager().columnNames)
    }

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let dataManager = DataManager.newTestDataManager()

        // Get actual database columns using GRDB introspection
        guard let grdbQueue = dataManager.dbQueue as? GRDBQueue else {
            XCTFail("Expected GRDBQueue for database introspection")
            return
        }

        let tableColumns = try grdbQueue.dbPool.read { db -> Set<String> in
            let columns = try db.columns(in: DataManager.playlistsTableName)
            return Set(columns.map { $0.name })
        }

        // The database should have at least all the columns from columnNames
        let missingColumns = columnNames.subtracting(tableColumns)
        XCTAssertTrue(
            missingColumns.isEmpty,
            "Database table is missing columns from columnNames: \(missingColumns)"
        )
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoadPreservesAllFields() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let original = self.createFullyPopulatedEpisodeFilter()

            // Save using the current implementation (respects feature flag)
            dataManager.save(playlist: original)

            // Load it back
            guard let loaded = dataManager.findPlaylist(uuid: original.uuid) else {
                XCTFail("\(implementationName): Should be able to load saved filter")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "\(implementationName): uuid should match")
            XCTAssertEqual(loaded.playlistName, original.playlistName, "\(implementationName): playlistName should match")
            XCTAssertEqual(loaded.customIcon, original.customIcon, "\(implementationName): customIcon should match")
            XCTAssertEqual(loaded.filterAllPodcasts, original.filterAllPodcasts, "\(implementationName): filterAllPodcasts should match")
            XCTAssertEqual(loaded.filterAudioVideoType, original.filterAudioVideoType, "\(implementationName): filterAudioVideoType should match")
            XCTAssertEqual(loaded.filterDownloaded, original.filterDownloaded, "\(implementationName): filterDownloaded should match")
            XCTAssertEqual(loaded.filterFinished, original.filterFinished, "\(implementationName): filterFinished should match")
            XCTAssertEqual(loaded.filterNotDownloaded, original.filterNotDownloaded, "\(implementationName): filterNotDownloaded should match")
            XCTAssertEqual(loaded.filterPartiallyPlayed, original.filterPartiallyPlayed, "\(implementationName): filterPartiallyPlayed should match")
            XCTAssertEqual(loaded.filterStarred, original.filterStarred, "\(implementationName): filterStarred should match")
            XCTAssertEqual(loaded.filterUnplayed, original.filterUnplayed, "\(implementationName): filterUnplayed should match")
            XCTAssertEqual(loaded.filterHours, original.filterHours, "\(implementationName): filterHours should match")
            XCTAssertEqual(loaded.sortPosition, original.sortPosition, "\(implementationName): sortPosition should match")
            XCTAssertEqual(loaded.sortType, original.sortType, "\(implementationName): sortType should match")
            XCTAssertEqual(loaded.podcastUuids, original.podcastUuids, "\(implementationName): podcastUuids should match")
            XCTAssertEqual(loaded.autoDownloadEpisodes, original.autoDownloadEpisodes, "\(implementationName): autoDownloadEpisodes should match")
            XCTAssertEqual(loaded.autoDownloadLimit, original.autoDownloadLimit, "\(implementationName): autoDownloadLimit should match")
            XCTAssertEqual(loaded.filterDuration, original.filterDuration, "\(implementationName): filterDuration should match")
            XCTAssertEqual(loaded.longerThan, original.longerThan, "\(implementationName): longerThan should match")
            XCTAssertEqual(loaded.shorterThan, original.shorterThan, "\(implementationName): shorterThan should match")
            XCTAssertEqual(loaded.syncStatus, original.syncStatus, "\(implementationName): syncStatus should match")
            XCTAssertEqual(loaded.wasDeleted, original.wasDeleted, "\(implementationName): wasDeleted should match")
            XCTAssertEqual(loaded.manual, original.manual, "\(implementationName): manual should match")
            XCTAssertEqual(loaded.showArchivedEpisodes, original.showArchivedEpisodes, "\(implementationName): showArchivedEpisodes should match")
            XCTAssertEqual(loaded.id, original.id, "\(implementationName): id should match")
            XCTAssertEqual(
                try XCTUnwrap(loaded.playlistUpdateDate).timeIntervalSince1970,
                try XCTUnwrap(original.playlistUpdateDate).timeIntervalSince1970,
                accuracy: 1,
                "\(implementationName): playlistUpdateDate should match"
            )
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that filterDownloading is NOT persisted
    func testFilterDownloadingNotPersisted() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let filter = EpisodeFilter()
            filter.uuid = UUID().uuidString.lowercased()
            filter.playlistName = "Test Filter"
            // filterDownloading is a let constant set to true, can't change it

            dataManager.save(playlist: filter)

            // Load it back - filterDownloading should always be true (its default)
            guard let loaded = dataManager.findPlaylist(uuid: filter.uuid) else {
                XCTFail("\(implementationName): Should find saved filter")
                return
            }

            // filterDownloading should be true (its constant default, not persisted)
            XCTAssertTrue(loaded.filterDownloading, "\(implementationName): filterDownloading should always be true")
        }
    }

    /// Verifies that internal tracking properties are NOT persisted
    func testInternalTrackingPropertiesNotPersisted() throws {
        try runWithBothImplementations { dataManager, implementationName in
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
                XCTFail("\(implementationName): Should find saved filter")
                return
            }

            // Internal tracking properties should be false (not persisted)
            XCTAssertFalse(loaded.isNew, "\(implementationName): isNew should NOT be persisted")
            XCTAssertFalse(loaded.podcastSmartRuleApplied, "\(implementationName): podcastSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.episodesSmartRuleApplied, "\(implementationName): episodesSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.releaseDateSmartRuleApplied, "\(implementationName): releaseDateSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.mediaTypeSmartRuleApplied, "\(implementationName): mediaTypeSmartRuleApplied should NOT be persisted")
            XCTAssertFalse(loaded.downloadStatusSmartRuleApplied, "\(implementationName): downloadStatusSmartRuleApplied should NOT be persisted")
        }
    }

    // MARK: - GRDB Record Tests

    func testEncodedColumnsMatchLegacyColumnNames() throws {
        let encoded = try createFullyPopulatedEpisodeFilter().databaseDictionary

        XCTAssertEqual(
            Set(encoded.keys),
            columnNames,
            "GRDB should encode exactly the columns the legacy SQL path writes"
        )
    }

    func testEncodedColumnsExistInDatabaseSchema() throws {
        let dataManager = DataManager.newTestDataManager()
        let tableColumns = try dataManager.testDbQueue.dbPool.read { db -> Set<String> in
            Set(try db.columns(in: DataManager.playlistsTableName).map(\.name))
        }

        let encoded = try createFullyPopulatedEpisodeFilter().databaseDictionary
        let unknownColumns = Set(encoded.keys).subtracting(tableColumns)

        XCTAssertTrue(
            unknownColumns.isEmpty,
            "GRDB encodes columns that do not exist in the table: \(unknownColumns)"
        )
    }

    func testEncodesPropertyValues() throws {
        let filter = createFullyPopulatedEpisodeFilter()
        filter.id = 987654321

        let encoded = try filter.databaseDictionary

        XCTAssertEqual(Int64.fromDatabaseValue(try XCTUnwrap(encoded["id"])), 987654321)
        XCTAssertEqual(String.fromDatabaseValue(try XCTUnwrap(encoded["uuid"])), filter.uuid)
        XCTAssertEqual(String.fromDatabaseValue(try XCTUnwrap(encoded["playlistName"])), "Test Filter")
        XCTAssertEqual(String.fromDatabaseValue(try XCTUnwrap(encoded["podcastUuids"])), "uuid1,uuid2,uuid3")
        XCTAssertEqual(Int32.fromDatabaseValue(try XCTUnwrap(encoded["customIcon"])), 3)
        XCTAssertEqual(Int32.fromDatabaseValue(try XCTUnwrap(encoded["filterHours"])), 24)
        XCTAssertEqual(Int32.fromDatabaseValue(try XCTUnwrap(encoded["longerThan"])), 300)
        XCTAssertEqual(Int32.fromDatabaseValue(try XCTUnwrap(encoded["shorterThan"])), 3600)
        XCTAssertEqual(Bool.fromDatabaseValue(try XCTUnwrap(encoded["filterStarred"])), true)
        XCTAssertEqual(Bool.fromDatabaseValue(try XCTUnwrap(encoded["filterUnplayed"])), false)
        XCTAssertEqual(Bool.fromDatabaseValue(try XCTUnwrap(encoded["showArchivedEpisodes"])), true)
    }

    /// playlistUpdateDate is stored as a Unix timestamp, not GRDB's default Date format.
    /// The legacy read path reads it back with `rs.double(forColumn:)`, so a change
    /// here would break the playlist's last-updated date.
    func testPlaylistUpdateDateIsEncodedAsUnixTimestamp() throws {
        let filter = createFullyPopulatedEpisodeFilter()
        let encoded = try filter.databaseDictionary

        let playlistUpdateDate = try XCTUnwrap(encoded["playlistUpdateDate"])
        XCTAssertEqual(
            Double.fromDatabaseValue(playlistUpdateDate),
            filter.playlistUpdateDate?.timeIntervalSince1970,
            "playlistUpdateDate should encode as a Unix timestamp"
        )
    }

    func testNilPlaylistUpdateDateIsEncodedAsNull() throws {
        let filter = createFullyPopulatedEpisodeFilter()
        filter.playlistUpdateDate = nil

        let encoded = try filter.databaseDictionary

        XCTAssertEqual(encoded["playlistUpdateDate"], .null, "a nil playlistUpdateDate should encode as NULL")
    }

    func testTransientPropertiesAreNotEncoded() throws {
        let filter = createFullyPopulatedEpisodeFilter()
        filter.isNew = true
        filter.podcastSmartRuleApplied = true
        filter.episodesSmartRuleApplied = true
        filter.releaseDateSmartRuleApplied = true
        filter.mediaTypeSmartRuleApplied = true
        filter.downloadStatusSmartRuleApplied = true

        let encoded = try filter.databaseDictionary

        for name in [
            "filterDownloading", "isNew", "podcastSmartRuleApplied", "episodesSmartRuleApplied",
            "releaseDateSmartRuleApplied", "mediaTypeSmartRuleApplied", "downloadStatusSmartRuleApplied"
        ] {
            XCTAssertNil(encoded[name], "\(name) is transient and should not be encoded")
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
