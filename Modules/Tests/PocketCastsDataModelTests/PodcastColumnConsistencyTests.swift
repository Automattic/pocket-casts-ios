import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class PodcastColumnConsistencyTests: DataManagerTestCase {

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let tableColumns = try DataManager.newTestDataManager().testDbQueue.dbPool.read { db in
            Set(try db.columns(in: DataManager.podcastTableName).map(\.name))
        }
        let encodedColumns = Set(try Podcast().databaseDictionary.keys)

        XCTAssertEqual(
            encodedColumns.subtracting(tableColumns),
            [],
            "Podcast encodes columns the table doesn't have"
        )
        XCTAssertEqual(
            tableColumns.subtracting(encodedColumns),
            ["settings", "thumbnailURL", "wasDeleted"],
            "Table columns that saving a Podcast doesn't write"
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
            XCTAssertEqual(loaded.id, original.id, "id should match")
            XCTAssertEqual(loaded.uuid, original.uuid, "uuid should match")
            XCTAssertEqual(loaded.addedDate, original.addedDate, "addedDate should match")
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
            XCTAssertEqual(loaded.isExplicit, original.isExplicit, "isExplicit should match")
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

    // MARK: - GRDB Record Tests

    /// Dates are stored as Unix timestamps, not GRDB's default Date format.
    /// The legacy read path reads them back with `rs.double(forColumn:)`, so a change
    /// here would silently shift every podcast date.
    func testDatesAreEncodedAsUnixTimestamps() throws {
        let podcast = createFullyPopulatedPodcast()
        let encoded = try podcast.databaseDictionary

        let dates: [String: Date?] = [
            "addedDate": podcast.addedDate,
            "lastColorDownloadDate": podcast.lastColorDownloadDate,
            "latestEpisodeDate": podcast.latestEpisodeDate,
            "lastThumbnailDownloadDate": podcast.lastThumbnailDownloadDate,
            "estimatedNextEpisode": podcast.estimatedNextEpisode
        ]
        for (column, date) in dates {
            XCTAssertEqual(
                Double.fromDatabaseValue(try XCTUnwrap(encoded[column])),
                try XCTUnwrap(date).timeIntervalSince1970,
                "\(column) should encode as a Unix timestamp"
            )
        }
    }

    func testNilDatesAreEncodedAsNull() throws {
        let encoded = try Podcast().databaseDictionary

        for column in ["lastColorDownloadDate", "latestEpisodeDate", "lastThumbnailDownloadDate", "estimatedNextEpisode"] {
            XCTAssertEqual(encoded[column], .null, "a nil \(column) should encode as NULL")
        }
    }

    /// `addedDate` is `REAL NOT NULL`, so a nil date is stored as 0, which the
    /// legacy read path turns back into nil.
    func testNilAddedDateIsEncodedAsZero() throws {
        let encoded = try Podcast().databaseDictionary

        XCTAssertEqual(Double.fromDatabaseValue(try XCTUnwrap(encoded["addedDate"])), 0)
    }

    func testSavesPodcastWithNilAddedDate() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createFullyPopulatedPodcast()
            podcast.addedDate = nil

            dataManager.save(podcast: podcast)

            let loaded = try XCTUnwrap(dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true))
            XCTAssertNil(loaded.addedDate)
        }
    }

    /// A row stored with `addedDate` 0 loads with a nil date. Saving that podcast
    /// again has to update the row instead of failing the `NOT NULL` constraint.
    func testUpdatesPodcastWithNilAddedDate() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createFullyPopulatedPodcast()
            dataManager.save(podcast: podcast)

            podcast.addedDate = nil
            podcast.title = "Renamed"
            dataManager.save(podcast: podcast)

            let loaded = try XCTUnwrap(dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true))
            XCTAssertEqual(loaded.title, "Renamed")
            XCTAssertNil(loaded.addedDate)
        }
    }

    func testAutoArchiveEpisodeLimitIsStoredInEpisodeKeepSetting() throws {
        let podcast = createFullyPopulatedPodcast()
        let encoded = try podcast.databaseDictionary

        XCTAssertEqual(Int32.fromDatabaseValue(try XCTUnwrap(encoded["episodeKeepSetting"])), 10)
        XCTAssertNil(encoded["autoArchiveEpisodeLimit"])
        XCTAssertEqual(Podcast.Columns.autoArchiveEpisodeLimit.name, "episodeKeepSetting")
    }

    func testTransientPropertiesAreNotEncoded() throws {
        let podcast = createFullyPopulatedPodcast()
        podcast.cachedUnreadCount = 42
        podcast.forceRefreshEpisodeFrom = "some-episode-uuid"

        let encoded = try podcast.databaseDictionary

        for name in ["settings", "cachedUnreadCount", "forceRefreshEpisodeFrom"] {
            XCTAssertNil(encoded[name], "\(name) should not be encoded")
        }
    }

    func testDecodesRowWrittenByGRDB() throws {
        let dataManager = DataManager.newTestDataManager()
        let original = createFullyPopulatedPodcast()
        dataManager.save(podcast: original)

        let decoded = try dataManager.testDbQueue.dbPool.read { db in
            try Podcast.filter(Podcast.Columns.uuid == original.uuid).fetchOne(db)
        }

        let podcast = try XCTUnwrap(decoded, "should decode a Podcast from its own row")
        XCTAssertEqual(try podcast.databaseDictionary, try original.databaseDictionary)
    }

    /// Every property decodes with a fallback, so a row missing columns (an older
    /// schema, or a projection) yields defaults instead of throwing.
    func testDecodesRowWithMissingColumnsUsingDefaults() throws {
        let podcast = try Podcast(row: ["uuid": "abc"])

        let expected = Podcast()
        expected.uuid = "abc"
        XCTAssertEqual(try podcast.databaseDictionary, try expected.databaseDictionary)
    }

    func testDecodesRowWithNullColumnsUsingDefaults() throws {
        let columns = try Podcast().databaseDictionary.keys
        let row = Row(Dictionary(uniqueKeysWithValues: columns.map { ($0, nil as (any DatabaseValueConvertible)?) }))

        let podcast = try Podcast(row: row)

        XCTAssertEqual(try podcast.databaseDictionary, try Podcast().databaseDictionary)
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
        podcast.addedDate = Date(timeIntervalSince1970: 1690000000)
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
        podcast.isPaid = true
        podcast.licensing = 1
        podcast.showArchived = true
        podcast.refreshAvailable = true
        podcast.folderUuid = "folder-uuid-123"
        podcast.usedCustomEffectsBefore = true
        podcast.isPrivate = true
        podcast.isExplicit = true
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
