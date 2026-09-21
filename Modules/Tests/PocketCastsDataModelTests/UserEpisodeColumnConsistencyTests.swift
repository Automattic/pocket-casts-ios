import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class UserEpisodeColumnConsistencyTests: DataManagerTestCase {

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let tableColumns = try DataManager.newTestDataManager().testDbQueue.dbPool.read { db in
            Set(try db.columns(in: DataManager.userEpisodeTableName).map(\.name))
        }
        let encodedColumns = Set(try UserEpisode().databaseDictionary.keys)

        XCTAssertEqual(
            encodedColumns.subtracting(tableColumns),
            [],
            "UserEpisode encodes columns the table doesn't have"
        )
        XCTAssertEqual(
            tableColumns.subtracting(encodedColumns),
            ["contentType"],
            "Table columns that saving a UserEpisode doesn't write"
        )
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoadPreservesAllFields() throws {
        try runWithDataManager { dataManager in
            let original = self.createFullyPopulatedUserEpisode()

            dataManager.save(episode: original)

            // Load it back
            guard let loaded = dataManager.findUserEpisode(uuid: original.uuid) else {
                XCTFail("Should be able to load saved episode")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.id, original.id, "id should match")
            XCTAssertEqual(loaded.uuid, original.uuid, "uuid should match")
            XCTAssertEqual(loaded.addedDate, original.addedDate, "addedDate should match")
            XCTAssertEqual(loaded.lastDownloadAttemptDate, original.lastDownloadAttemptDate, "lastDownloadAttemptDate should match")
            XCTAssertEqual(loaded.publishedDate, original.publishedDate, "publishedDate should match")
            XCTAssertEqual(loaded.title, original.title, "title should match")
            XCTAssertEqual(loaded.duration, original.duration, "duration should match")
            XCTAssertEqual(loaded.playedUpTo, original.playedUpTo, "playedUpTo should match")
            XCTAssertEqual(loaded.playingStatus, original.playingStatus, "playingStatus should match")
            XCTAssertEqual(loaded.episodeStatus, original.episodeStatus, "episodeStatus should match")
            XCTAssertEqual(loaded.uploadStatus, original.uploadStatus, "uploadStatus should match")
            XCTAssertEqual(loaded.autoDownloadStatus, original.autoDownloadStatus, "autoDownloadStatus should match")
            XCTAssertEqual(loaded.sizeInBytes, original.sizeInBytes, "sizeInBytes should match")
            XCTAssertEqual(loaded.fileType, original.fileType, "fileType should match")
            XCTAssertEqual(loaded.downloadUrl, original.downloadUrl, "downloadUrl should match")
            XCTAssertEqual(loaded.downloadTaskId, original.downloadTaskId, "downloadTaskId should match")
            XCTAssertEqual(loaded.uploadTaskId, original.uploadTaskId, "uploadTaskId should match")
            XCTAssertEqual(loaded.imageUrl, original.imageUrl, "imageUrl should match")
            XCTAssertEqual(loaded.imageColor, original.imageColor, "imageColor should match")
            XCTAssertEqual(loaded.hasCustomImage, original.hasCustomImage, "hasCustomImage should match")
            XCTAssertEqual(loaded.cachedFrameCount, original.cachedFrameCount, "cachedFrameCount should match")
            XCTAssertEqual(loaded.playingStatusModified, original.playingStatusModified, "playingStatusModified should match")
            XCTAssertEqual(loaded.playedUpToModified, original.playedUpToModified, "playedUpToModified should match")
            XCTAssertEqual(loaded.titleModified, original.titleModified, "titleModified should match")
            XCTAssertEqual(loaded.durationModified, original.durationModified, "durationModified should match")
            XCTAssertEqual(loaded.imageModified, original.imageModified, "imageModified should match")
            XCTAssertEqual(loaded.imageColorModified, original.imageColorModified, "imageColorModified should match")
            XCTAssertEqual(loaded.downloadErrorDetails, original.downloadErrorDetails, "downloadErrorDetails should match")
            XCTAssertEqual(loaded.playbackErrorDetails, original.playbackErrorDetails, "playbackErrorDetails should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that contentType is NOT persisted by save() but IS persisted by saveContentType()
    func testContentTypeNotPersistedBySave() throws {
        try runWithDataManager { dataManager in
            let episode = UserEpisode()
            episode.uuid = UUID().uuidString
            episode.title = "ContentType Test"
            episode.addedDate = Date()
            episode.contentType = "audio/mpeg"  // Set contentType

            dataManager.save(episode: episode)

            // Load it back - contentType should NOT be saved by save()
            guard let loaded = dataManager.findUserEpisode(uuid: episode.uuid) else {
                XCTFail("Should find saved episode")
                return
            }

            // contentType should be nil because save() doesn't persist it
            XCTAssertNil(loaded.contentType, "contentType should NOT be persisted by save() - use saveContentType() instead")
        }
    }

    func testContentTypePersistedBySaveContentType() throws {
        try runWithDataManager { dataManager in
            let episode = UserEpisode()
            episode.uuid = UUID().uuidString
            episode.title = "ContentType Test"
            episode.addedDate = Date()
            dataManager.save(episode: episode)

            // Use the dedicated method to save contentType
            dataManager.saveEpisode(contentType: "audio/mpeg", episode: episode)

            guard let loaded = dataManager.findUserEpisode(uuid: episode.uuid) else {
                XCTFail("Should find saved episode")
                return
            }

            XCTAssertEqual(loaded.contentType, "audio/mpeg", "contentType should be persisted by saveContentType()")
        }
    }

    // MARK: - GRDB Record Tests

    /// Dates are stored as Unix timestamps, not GRDB's default Date format.
    /// The legacy read path reads them back with `rs.double(forColumn:)`, so a change
    /// here would silently shift every user episode date.
    func testDatesAreEncodedAsUnixTimestamps() throws {
        let episode = createFullyPopulatedUserEpisode()
        let encoded = try episode.databaseDictionary

        let dates: [String: Date?] = [
            "addedDate": episode.addedDate,
            "lastDownloadAttemptDate": episode.lastDownloadAttemptDate,
            "publishedDate": episode.publishedDate
        ]
        for (column, date) in dates {
            XCTAssertEqual(
                Double.fromDatabaseValue(try XCTUnwrap(encoded[column])),
                try XCTUnwrap(date).timeIntervalSince1970,
                "\(column) should encode as a Unix timestamp"
            )
        }
    }

    func testNilPublishedDateIsEncodedAsNull() throws {
        let encoded = try UserEpisode().databaseDictionary

        XCTAssertEqual(encoded["publishedDate"], .null, "a nil publishedDate should encode as NULL")
    }

    /// These columns are `NOT NULL`, so a nil date is stored as 0 instead of NULL.
    /// The legacy read path turns 0 back into nil.
    func testNilDatesInNotNullColumnsAreEncodedAsZero() throws {
        let encoded = try UserEpisode().databaseDictionary

        for column in ["addedDate", "lastDownloadAttemptDate"] {
            XCTAssertEqual(Double.fromDatabaseValue(try XCTUnwrap(encoded[column])), 0, "a nil \(column) should encode as 0")
        }
    }

    func testSavesUserEpisodeWithNilAddedDate() throws {
        try runWithDataManager { dataManager in
            let episode = self.createFullyPopulatedUserEpisode()
            episode.addedDate = nil

            dataManager.save(episode: episode)

            let loaded = try XCTUnwrap(dataManager.findUserEpisode(uuid: episode.uuid))
            XCTAssertNil(loaded.addedDate)
        }
    }

    /// A row stored with `addedDate` 0 loads with a nil date. Saving that episode
    /// again has to update the row instead of failing the `NOT NULL` constraint.
    func testUpdatesUserEpisodeWithNilAddedDate() throws {
        try runWithDataManager { dataManager in
            let episode = self.createFullyPopulatedUserEpisode()
            dataManager.save(episode: episode)

            episode.addedDate = nil
            episode.title = "Renamed"
            dataManager.save(episode: episode)

            let loaded = try XCTUnwrap(dataManager.findUserEpisode(uuid: episode.uuid))
            XCTAssertEqual(loaded.title, "Renamed")
            XCTAssertNil(loaded.addedDate)
        }
    }

    func testTransientPropertiesAreNotEncoded() throws {
        let episode = createFullyPopulatedUserEpisode()
        episode.contentType = "audio/mpeg"
        episode.hasOnlyUuid = true
        episode.deselectedChapters = "1,3,5"
        episode.deselectedChaptersModified = 777
        episode.archived = true
        episode.keepEpisode = true
        episode.wasDeleted = true

        let encoded = try episode.databaseDictionary

        for name in [
            "contentType", "hasOnlyUuid", "deselectedChapters", "deselectedChaptersModified",
            "archived", "keepEpisode", "wasDeleted"
        ] {
            XCTAssertNil(encoded[name], "\(name) should not be encoded")
        }
    }

    func testDecodesRowWrittenByGRDB() throws {
        let dataManager = DataManager.newTestDataManager()
        let original = createFullyPopulatedUserEpisode()
        dataManager.save(episode: original)

        let decoded = try dataManager.testDbQueue.dbPool.read { db in
            try UserEpisode.filter(UserEpisode.Columns.uuid == original.uuid).fetchOne(db)
        }

        let episode = try XCTUnwrap(decoded, "should decode a UserEpisode from its own row")
        XCTAssertEqual(try episode.databaseDictionary, try original.databaseDictionary)
    }

    /// Every property decodes with a fallback, so a row missing columns (an older
    /// schema, or a projection) yields defaults instead of throwing.
    func testDecodesRowWithMissingColumnsUsingDefaults() throws {
        let episode = try UserEpisode(row: ["uuid": "abc"])

        let expected = UserEpisode()
        expected.uuid = "abc"
        XCTAssertEqual(try episode.databaseDictionary, try expected.databaseDictionary)
        XCTAssertNil(episode.lastDownloadAttemptDate)
    }

    func testDecodesRowWithNullColumnsUsingDefaults() throws {
        let columns = try UserEpisode().databaseDictionary.keys
        let row = Row(Dictionary(uniqueKeysWithValues: columns.map { ($0, nil as (any DatabaseValueConvertible)?) }))

        let episode = try UserEpisode(row: row)

        XCTAssertEqual(try episode.databaseDictionary, try UserEpisode().databaseDictionary)
        XCTAssertNil(episode.lastDownloadAttemptDate)
    }

    // MARK: - Helpers

    private func assertEpisodesMatch(_ original: UserEpisode, _ loaded: UserEpisode, context: String) {
        XCTAssertEqual(loaded.uuid, original.uuid, "\(context): uuid should match")
        XCTAssertEqual(loaded.title, original.title, "\(context): title should match")
        XCTAssertEqual(loaded.duration, original.duration, "\(context): duration should match")
        XCTAssertEqual(loaded.playedUpTo, original.playedUpTo, "\(context): playedUpTo should match")
        XCTAssertEqual(loaded.playingStatus, original.playingStatus, "\(context): playingStatus should match")
        XCTAssertEqual(loaded.episodeStatus, original.episodeStatus, "\(context): episodeStatus should match")
        XCTAssertEqual(loaded.uploadStatus, original.uploadStatus, "\(context): uploadStatus should match")
        XCTAssertEqual(loaded.autoDownloadStatus, original.autoDownloadStatus, "\(context): autoDownloadStatus should match")
        XCTAssertEqual(loaded.sizeInBytes, original.sizeInBytes, "\(context): sizeInBytes should match")
        XCTAssertEqual(loaded.fileType, original.fileType, "\(context): fileType should match")
        XCTAssertEqual(loaded.downloadUrl, original.downloadUrl, "\(context): downloadUrl should match")
        XCTAssertEqual(loaded.downloadTaskId, original.downloadTaskId, "\(context): downloadTaskId should match")
        XCTAssertEqual(loaded.uploadTaskId, original.uploadTaskId, "\(context): uploadTaskId should match")
        XCTAssertEqual(loaded.imageUrl, original.imageUrl, "\(context): imageUrl should match")
        XCTAssertEqual(loaded.imageColor, original.imageColor, "\(context): imageColor should match")
        XCTAssertEqual(loaded.hasCustomImage, original.hasCustomImage, "\(context): hasCustomImage should match")
        XCTAssertEqual(loaded.cachedFrameCount, original.cachedFrameCount, "\(context): cachedFrameCount should match")
        XCTAssertEqual(loaded.playingStatusModified, original.playingStatusModified, "\(context): playingStatusModified should match")
        XCTAssertEqual(loaded.playedUpToModified, original.playedUpToModified, "\(context): playedUpToModified should match")
        XCTAssertEqual(loaded.titleModified, original.titleModified, "\(context): titleModified should match")
        XCTAssertEqual(loaded.durationModified, original.durationModified, "\(context): durationModified should match")
        XCTAssertEqual(loaded.imageModified, original.imageModified, "\(context): imageModified should match")
        XCTAssertEqual(loaded.imageColorModified, original.imageColorModified, "\(context): imageColorModified should match")
        XCTAssertEqual(loaded.downloadErrorDetails, original.downloadErrorDetails, "\(context): downloadErrorDetails should match")
        XCTAssertEqual(loaded.playbackErrorDetails, original.playbackErrorDetails, "\(context): playbackErrorDetails should match")
    }

    private func createFullyPopulatedUserEpisode() -> UserEpisode {
        let episode = UserEpisode()
        episode.uuid = UUID().uuidString
        episode.title = "Test Episode Title"
        episode.addedDate = Date(timeIntervalSince1970: 1700000000)
        episode.lastDownloadAttemptDate = Date(timeIntervalSince1970: 1700000100)
        episode.downloadErrorDetails = "Test error"
        episode.downloadTaskId = "download-task-123"
        episode.downloadUrl = "https://example.com/episode.mp3"
        episode.episodeStatus = DownloadStatus.downloaded.rawValue
        episode.fileType = "audio/mpeg"
        episode.playedUpTo = 123.45
        episode.duration = 3600.0
        episode.durationModified = 111
        episode.playingStatus = PlayingStatus.inProgress.rawValue
        episode.autoDownloadStatus = AutoDownloadStatus.autoDownloaded.rawValue
        episode.publishedDate = Date(timeIntervalSince1970: 1690000000)
        episode.sizeInBytes = 1024000
        episode.playingStatusModified = 222
        episode.playedUpToModified = 333
        episode.titleModified = 444
        episode.playbackErrorDetails = "Playback error"
        episode.cachedFrameCount = 100
        episode.uploadStatus = UploadStatus.uploaded.rawValue
        episode.uploadTaskId = "upload-task-456"
        episode.imageUrl = "https://example.com/image.jpg"
        episode.imageModified = 555
        episode.imageColor = 5
        episode.imageColorModified = 666
        episode.hasCustomImage = true
        return episode
    }
}
