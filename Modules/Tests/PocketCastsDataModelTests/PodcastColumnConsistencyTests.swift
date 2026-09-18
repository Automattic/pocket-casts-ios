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
        try runWithDataManager { dataManager in
            let original = self.createFullyPopulatedPodcast()

            dataManager.save(podcast: original)

            // Load it back
            guard let loaded = dataManager.findPodcast(uuid: original.uuid, includeUnsubscribed: true) else {
                XCTFail("Should be able to load saved podcast")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "uuid should match")
            XCTAssertEqual(loaded.title, original.title, "title should match")
            XCTAssertEqual(loaded.author, original.author, "author should match")
            XCTAssertEqual(loaded.podcastDescription, original.podcastDescription, "podcastDescription should match")
            XCTAssertEqual(loaded.podcastHTMLDescription, original.podcastHTMLDescription, "podcastHTMLDescription should match")
            XCTAssertEqual(loaded.podcastUrl, original.podcastUrl, "podcastUrl should match")
            XCTAssertEqual(loaded.imageURL, original.imageURL, "imageURL should match")
            XCTAssertEqual(loaded.mediaType, original.mediaType, "mediaType should match")
            XCTAssertEqual(loaded.subscribed, original.subscribed, "subscribed should match")
            XCTAssertEqual(loaded.sortOrder, original.sortOrder, "sortOrder should match")
            XCTAssertEqual(loaded.autoDownloadSetting, original.autoDownloadSetting, "autoDownloadSetting should match")
            XCTAssertEqual(loaded.autoAddToUpNext, original.autoAddToUpNext, "autoAddToUpNext should match")
            XCTAssertEqual(loaded.autoArchiveEpisodeLimit, original.autoArchiveEpisodeLimit, "autoArchiveEpisodeLimit should match")
            XCTAssertEqual(loaded.overrideGlobalEffects, original.overrideGlobalEffects, "overrideGlobalEffects should match")
            XCTAssertEqual(loaded.playbackSpeed, original.playbackSpeed, "playbackSpeed should match")
            XCTAssertEqual(loaded.boostVolume, original.boostVolume, "boostVolume should match")
            XCTAssertEqual(loaded.trimSilenceAmount, original.trimSilenceAmount, "trimSilenceAmount should match")
            XCTAssertEqual(loaded.startFrom, original.startFrom, "startFrom should match")
            XCTAssertEqual(loaded.skipLast, original.skipLast, "skipLast should match")
            XCTAssertEqual(loaded.syncStatus, original.syncStatus, "syncStatus should match")
            XCTAssertEqual(loaded.colorVersion, original.colorVersion, "colorVersion should match")
            XCTAssertEqual(loaded.pushEnabled, original.pushEnabled, "pushEnabled should match")
            XCTAssertEqual(loaded.episodeSortOrder, original.episodeSortOrder, "episodeSortOrder should match")
            XCTAssertEqual(loaded.episodeGrouping, original.episodeGrouping, "episodeGrouping should match")
            XCTAssertEqual(loaded.showType, original.showType, "showType should match")
            XCTAssertEqual(loaded.overrideGlobalArchive, original.overrideGlobalArchive, "overrideGlobalArchive should match")
            XCTAssertEqual(loaded.autoArchivePlayedAfter, original.autoArchivePlayedAfter, "autoArchivePlayedAfter should match")
            XCTAssertEqual(loaded.autoArchiveInactiveAfter, original.autoArchiveInactiveAfter, "autoArchiveInactiveAfter should match")
            XCTAssertEqual(loaded.isPaid, original.isPaid, "isPaid should match")
            XCTAssertEqual(loaded.licensing, original.licensing, "licensing should match")
            XCTAssertEqual(loaded.showArchived, original.showArchived, "showArchived should match")
            XCTAssertEqual(loaded.refreshAvailable, original.refreshAvailable, "refreshAvailable should match")
            XCTAssertEqual(loaded.folderUuid, original.folderUuid, "folderUuid should match")
            XCTAssertEqual(loaded.usedCustomEffectsBefore, original.usedCustomEffectsBefore, "usedCustomEffectsBefore should match")
            XCTAssertEqual(loaded.isPrivate, original.isPrivate, "isPrivate should match")
            XCTAssertEqual(loaded.fundingURL, original.fundingURL, "fundingURL should match")
            XCTAssertEqual(loaded.networkListId, original.networkListId, "networkListId should match")
            // Color fields
            XCTAssertEqual(loaded.backgroundColor, original.backgroundColor, "backgroundColor should match")
            XCTAssertEqual(loaded.detailColor, original.detailColor, "detailColor should match")
            XCTAssertEqual(loaded.primaryColor, original.primaryColor, "primaryColor should match")
            XCTAssertEqual(loaded.secondaryColor, original.secondaryColor, "secondaryColor should match")
            XCTAssertEqual(loaded.lastColorDownloadDate, original.lastColorDownloadDate, "lastColorDownloadDate should match")
            // Episode metadata fields
            XCTAssertEqual(loaded.latestEpisodeUuid, original.latestEpisodeUuid, "latestEpisodeUuid should match")
            XCTAssertEqual(loaded.latestEpisodeDate, original.latestEpisodeDate, "latestEpisodeDate should match")
            XCTAssertEqual(loaded.estimatedNextEpisode, original.estimatedNextEpisode, "estimatedNextEpisode should match")
            XCTAssertEqual(loaded.episodeFrequency, original.episodeFrequency, "episodeFrequency should match")
            // Thumbnail fields
            XCTAssertEqual(loaded.lastThumbnailDownloadDate, original.lastThumbnailDownloadDate, "lastThumbnailDownloadDate should match")
            XCTAssertEqual(loaded.thumbnailStatus, original.thumbnailStatus, "thumbnailStatus should match")
            // Other fields
            XCTAssertEqual(loaded.podcastCategory, original.podcastCategory, "podcastCategory should match")
            XCTAssertEqual(loaded.lastUpdatedAt, original.lastUpdatedAt, "lastUpdatedAt should match")
            XCTAssertEqual(loaded.excludeFromAutoArchive, original.excludeFromAutoArchive, "excludeFromAutoArchive should match")
            XCTAssertEqual(loaded.fullSyncLastSyncAt, original.fullSyncLastSyncAt, "fullSyncLastSyncAt should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that cachedUnreadCount is NOT persisted (marked with @GRDBIgnore)
    func testCachedUnreadCountNotPersisted() throws {
        try runWithDataManager { dataManager in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            podcast.cachedUnreadCount = 42  // Set ignored property

            dataManager.save(podcast: podcast)

            // Load it back - cachedUnreadCount should be default (0)
            guard let loaded = dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true) else {
                XCTFail("Should find saved podcast")
                return
            }

            // cachedUnreadCount should be 0 (not persisted)
            XCTAssertEqual(loaded.cachedUnreadCount, 0, "cachedUnreadCount should NOT be persisted")
        }
    }

    /// Verifies that forceRefreshEpisodeFrom is NOT persisted (marked with @GRDBIgnore)
    func testForceRefreshEpisodeFromNotPersisted() throws {
        try runWithDataManager { dataManager in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            podcast.forceRefreshEpisodeFrom = "some-episode-uuid"  // Set ignored property

            dataManager.save(podcast: podcast)

            // Load it back - forceRefreshEpisodeFrom should be nil
            guard let loaded = dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true) else {
                XCTFail("Should find saved podcast")
                return
            }

            // forceRefreshEpisodeFrom should be nil (not persisted)
            XCTAssertNil(loaded.forceRefreshEpisodeFrom, "forceRefreshEpisodeFrom should NOT be persisted")
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
        podcast.networkListId = "cdb75bc0-9f5a-4217-b1ca-f573821a7913"
        // Color fields
        podcast.backgroundColor = "#FFFFFF"
        podcast.detailColor = "#000000"
        podcast.primaryColor = "#FF0000"
        podcast.secondaryColor = "#00FF00"
        podcast.lastColorDownloadDate = Date(timeIntervalSince1970: 1700000000)
        // Episode metadata fields
        podcast.latestEpisodeUuid = "latest-episode-uuid-123"
        podcast.latestEpisodeDate = Date(timeIntervalSince1970: 1700000000)
        podcast.estimatedNextEpisode = Date(timeIntervalSince1970: 1700100000)
        podcast.episodeFrequency = "weekly"
        // Thumbnail fields
        podcast.lastThumbnailDownloadDate = Date(timeIntervalSince1970: 1700000000)
        podcast.thumbnailStatus = 2
        // Other fields
        podcast.podcastCategory = "Technology"
        podcast.lastUpdatedAt = "2024-01-01T00:00:00Z"
        podcast.excludeFromAutoArchive = true
        podcast.fullSyncLastSyncAt = "2024-01-01T00:00:00Z"
        return podcast
    }
}
