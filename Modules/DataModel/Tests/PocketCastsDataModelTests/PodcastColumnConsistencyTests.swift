import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests to ensure the legacy SQL columnNames and GRDB-persisted columns remain in sync.
/// These tests prevent the issue where GRDB might persist a field that the legacy SQL path ignores
/// (or vice versa), causing inconsistent behavior when the feature flag is toggled.
final class PodcastColumnConsistencyTests: DataManagerTestCase {

    /// Access columnNames directly from PodcastDataManager (the source of truth for legacy SQL).
    private var columnNames: Set<String> {
        Set(PodcastDataManager().columnNames)
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
            let columns = try db.columns(in: DataManager.podcastTableName)
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
            let original = self.createFullyPopulatedPodcast()

            // Save using the current implementation (respects feature flag)
            dataManager.save(podcast: original)

            // Load it back
            guard let loaded = dataManager.findPodcast(uuid: original.uuid, includeUnsubscribed: true) else {
                XCTFail("\(implementationName): Should be able to load saved podcast")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "\(implementationName): uuid should match")
            XCTAssertEqual(loaded.title, original.title, "\(implementationName): title should match")
            XCTAssertEqual(loaded.author, original.author, "\(implementationName): author should match")
            XCTAssertEqual(loaded.podcastDescription, original.podcastDescription, "\(implementationName): podcastDescription should match")
            XCTAssertEqual(loaded.podcastUrl, original.podcastUrl, "\(implementationName): podcastUrl should match")
            XCTAssertEqual(loaded.imageURL, original.imageURL, "\(implementationName): imageURL should match")
            XCTAssertEqual(loaded.mediaType, original.mediaType, "\(implementationName): mediaType should match")
            XCTAssertEqual(loaded.subscribed, original.subscribed, "\(implementationName): subscribed should match")
            XCTAssertEqual(loaded.sortOrder, original.sortOrder, "\(implementationName): sortOrder should match")
            XCTAssertEqual(loaded.autoDownloadSetting, original.autoDownloadSetting, "\(implementationName): autoDownloadSetting should match")
            XCTAssertEqual(loaded.autoAddToUpNext, original.autoAddToUpNext, "\(implementationName): autoAddToUpNext should match")
            XCTAssertEqual(loaded.autoArchiveEpisodeLimit, original.autoArchiveEpisodeLimit, "\(implementationName): autoArchiveEpisodeLimit should match")
            XCTAssertEqual(loaded.overrideGlobalEffects, original.overrideGlobalEffects, "\(implementationName): overrideGlobalEffects should match")
            XCTAssertEqual(loaded.playbackSpeed, original.playbackSpeed, "\(implementationName): playbackSpeed should match")
            XCTAssertEqual(loaded.boostVolume, original.boostVolume, "\(implementationName): boostVolume should match")
            XCTAssertEqual(loaded.trimSilenceAmount, original.trimSilenceAmount, "\(implementationName): trimSilenceAmount should match")
            XCTAssertEqual(loaded.startFrom, original.startFrom, "\(implementationName): startFrom should match")
            XCTAssertEqual(loaded.skipLast, original.skipLast, "\(implementationName): skipLast should match")
            XCTAssertEqual(loaded.syncStatus, original.syncStatus, "\(implementationName): syncStatus should match")
            XCTAssertEqual(loaded.colorVersion, original.colorVersion, "\(implementationName): colorVersion should match")
            XCTAssertEqual(loaded.pushEnabled, original.pushEnabled, "\(implementationName): pushEnabled should match")
            XCTAssertEqual(loaded.episodeSortOrder, original.episodeSortOrder, "\(implementationName): episodeSortOrder should match")
            XCTAssertEqual(loaded.episodeGrouping, original.episodeGrouping, "\(implementationName): episodeGrouping should match")
            XCTAssertEqual(loaded.showType, original.showType, "\(implementationName): showType should match")
            XCTAssertEqual(loaded.overrideGlobalArchive, original.overrideGlobalArchive, "\(implementationName): overrideGlobalArchive should match")
            XCTAssertEqual(loaded.autoArchivePlayedAfter, original.autoArchivePlayedAfter, "\(implementationName): autoArchivePlayedAfter should match")
            XCTAssertEqual(loaded.autoArchiveInactiveAfter, original.autoArchiveInactiveAfter, "\(implementationName): autoArchiveInactiveAfter should match")
            XCTAssertEqual(loaded.isPaid, original.isPaid, "\(implementationName): isPaid should match")
            XCTAssertEqual(loaded.licensing, original.licensing, "\(implementationName): licensing should match")
            XCTAssertEqual(loaded.showArchived, original.showArchived, "\(implementationName): showArchived should match")
            XCTAssertEqual(loaded.refreshAvailable, original.refreshAvailable, "\(implementationName): refreshAvailable should match")
            XCTAssertEqual(loaded.folderUuid, original.folderUuid, "\(implementationName): folderUuid should match")
            XCTAssertEqual(loaded.usedCustomEffectsBefore, original.usedCustomEffectsBefore, "\(implementationName): usedCustomEffectsBefore should match")
            XCTAssertEqual(loaded.isPrivate, original.isPrivate, "\(implementationName): isPrivate should match")
            XCTAssertEqual(loaded.fundingURL, original.fundingURL, "\(implementationName): fundingURL should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that cachedUnreadCount is NOT persisted (marked with @GRDBIgnore)
    func testCachedUnreadCountNotPersisted() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            podcast.cachedUnreadCount = 42  // Set ignored property

            dataManager.save(podcast: podcast)

            // Load it back - cachedUnreadCount should be default (0)
            guard let loaded = dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true) else {
                XCTFail("\(implementationName): Should find saved podcast")
                return
            }

            // cachedUnreadCount should be 0 (not persisted)
            XCTAssertEqual(loaded.cachedUnreadCount, 0, "\(implementationName): cachedUnreadCount should NOT be persisted")
        }
    }

    /// Verifies that forceRefreshEpisodeFrom is NOT persisted (marked with @GRDBIgnore)
    func testForceRefreshEpisodeFromNotPersisted() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            podcast.forceRefreshEpisodeFrom = "some-episode-uuid"  // Set ignored property

            dataManager.save(podcast: podcast)

            // Load it back - forceRefreshEpisodeFrom should be nil
            guard let loaded = dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true) else {
                XCTFail("\(implementationName): Should find saved podcast")
                return
            }

            // forceRefreshEpisodeFrom should be nil (not persisted)
            XCTAssertNil(loaded.forceRefreshEpisodeFrom, "\(implementationName): forceRefreshEpisodeFrom should NOT be persisted")
        }
    }

    // MARK: - Helpers

    private func createFullyPopulatedPodcast() -> Podcast {
        let podcast = Podcast()
        podcast.uuid = UUID().uuidString.lowercased()
        podcast.title = "Test Podcast Title"
        podcast.author = "Test Author"
        podcast.podcastDescription = "A test podcast description"
        podcast.podcastHTMLDescription = "<p>A test podcast description</p>"
        podcast.podcastUrl = "https://example.com/feed.xml"
        podcast.imageURL = "https://example.com/image.jpg"
        podcast.mediaType = "audio"
        podcast.addedDate = Date()
        podcast.subscribed = 1
        podcast.sortOrder = 5
        podcast.autoDownloadSetting = AutoDownloadSetting.latest.rawValue
        podcast.autoAddToUpNext = AutoAddToUpNextSetting.addLast.rawValue
        podcast.autoArchiveEpisodeLimit = 10
        podcast.overrideGlobalEffects = true
        podcast.playbackSpeed = 1.5
        podcast.boostVolume = true
        podcast.trimSilenceAmount = 2
        podcast.startFrom = 30
        podcast.skipLast = 15
        podcast.syncStatus = SyncStatus.synced.rawValue
        podcast.colorVersion = 2
        podcast.pushEnabled = true
        podcast.episodeSortOrder = 2
        podcast.episodeGrouping = 1
        podcast.showType = "episodic"
        podcast.overrideGlobalArchive = true
        podcast.autoArchivePlayedAfter = 86400
        podcast.autoArchiveInactiveAfter = 604800
        podcast.isPaid = false
        podcast.licensing = 0
        podcast.showArchived = true
        podcast.refreshAvailable = true
        podcast.folderUuid = "folder-uuid-123"
        podcast.usedCustomEffectsBefore = true
        podcast.isPrivate = false
        podcast.fundingURL = "https://example.com/support"
        return podcast
    }
}
