import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class EpisodeColumnConsistencyTests: DataManagerTestCase {

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let tableColumns = try DataManager.newTestDataManager().dbQueue.dbPool.read { db in
            Set(try db.columns(in: DataManager.episodeTableName).map(\.name))
        }
        let encodedColumns = Set(try Episode().databaseDictionary.keys)

        XCTAssertEqual(
            encodedColumns.subtracting(tableColumns),
            [],
            "Episode encodes columns the table doesn't have"
        )
        XCTAssertEqual(
            tableColumns.subtracting(encodedColumns),
            ["metadata", "showNotes", "wasDeletedModified"],
            "Table columns that saving an Episode doesn't write"
        )
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoadPreservesAllFields() throws {
        try runWithDataManager { dataManager in
            // Create a podcast first since episodes require a parent podcast
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            dataManager.save(podcast: podcast)

            let original = self.createFullyPopulatedEpisode(podcastUuid: podcast.uuid, podcastId: podcast.id)

            dataManager.save(episode: original)

            // Load it back
            guard let loaded = dataManager.findEpisode(uuid: original.uuid) else {
                XCTFail("Should be able to load saved episode")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.id, original.id, "id should match")
            XCTAssertEqual(loaded.uuid, original.uuid, "uuid should match")
            XCTAssertEqual(loaded.podcastUuid, original.podcastUuid, "podcastUuid should match")
            XCTAssertEqual(loaded.title, original.title, "title should match")
            XCTAssertEqual(loaded.episodeDescription, original.episodeDescription, "episodeDescription should match")
            XCTAssertEqual(loaded.detailedDescription, original.detailedDescription, "detailedDescription should match")
            XCTAssertEqual(loaded.duration, original.duration, "duration should match")
            XCTAssertEqual(loaded.playedUpTo, original.playedUpTo, "playedUpTo should match")
            XCTAssertEqual(loaded.playingStatus, original.playingStatus, "playingStatus should match")
            XCTAssertEqual(loaded.episodeStatus, original.episodeStatus, "episodeStatus should match")
            XCTAssertEqual(loaded.autoDownloadStatus, original.autoDownloadStatus, "autoDownloadStatus should match")
            XCTAssertEqual(loaded.sizeInBytes, original.sizeInBytes, "sizeInBytes should match")
            XCTAssertEqual(loaded.fileType, original.fileType, "fileType should match")
            XCTAssertEqual(loaded.contentType, original.contentType, "contentType should match")
            XCTAssertEqual(loaded.downloadUrl, original.downloadUrl, "downloadUrl should match")
            XCTAssertEqual(loaded.hlsUrl, original.hlsUrl, "hlsUrl should match")
            XCTAssertEqual(loaded.downloadTaskId, original.downloadTaskId, "downloadTaskId should match")
            XCTAssertEqual(loaded.keepEpisode, original.keepEpisode, "keepEpisode should match")
            XCTAssertEqual(loaded.cachedFrameCount, original.cachedFrameCount, "cachedFrameCount should match")
            XCTAssertEqual(loaded.playingStatusModified, original.playingStatusModified, "playingStatusModified should match")
            XCTAssertEqual(loaded.playedUpToModified, original.playedUpToModified, "playedUpToModified should match")
            XCTAssertEqual(loaded.durationModified, original.durationModified, "durationModified should match")
            XCTAssertEqual(loaded.keepEpisodeModified, original.keepEpisodeModified, "keepEpisodeModified should match")
            XCTAssertEqual(loaded.starredModified, original.starredModified, "starredModified should match")
            XCTAssertEqual(loaded.downloadErrorDetails, original.downloadErrorDetails, "downloadErrorDetails should match")
            XCTAssertEqual(loaded.playbackErrorDetails, original.playbackErrorDetails, "playbackErrorDetails should match")
            XCTAssertEqual(loaded.episodeNumber, original.episodeNumber, "episodeNumber should match")
            XCTAssertEqual(loaded.seasonNumber, original.seasonNumber, "seasonNumber should match")
            XCTAssertEqual(loaded.episodeType, original.episodeType, "episodeType should match")
            XCTAssertEqual(loaded.archived, original.archived, "archived should match")
            XCTAssertEqual(loaded.archivedModified, original.archivedModified, "archivedModified should match")
            XCTAssertEqual(loaded.excludeFromEpisodeLimit, original.excludeFromEpisodeLimit, "excludeFromEpisodeLimit should match")
            XCTAssertEqual(loaded.deselectedChapters, original.deselectedChapters, "deselectedChapters should match")
            XCTAssertEqual(loaded.deselectedChaptersModified, original.deselectedChaptersModified, "deselectedChaptersModified should match")
            XCTAssertEqual(loaded.wasDeleted, original.wasDeleted, "wasDeleted should match")
            XCTAssertEqual(loaded.hasGeneratedTranscript, original.hasGeneratedTranscript, "hasGeneratedTranscript should match")
            XCTAssertEqual(loaded.podcast_id, original.podcast_id, "podcast_id should match")
            self.assertDatesEqual(loaded.addedDate, original.addedDate, "addedDate should match")
            self.assertDatesEqual(loaded.publishedDate, original.publishedDate, "publishedDate should match")
            self.assertDatesEqual(loaded.lastDownloadAttemptDate, original.lastDownloadAttemptDate, "lastDownloadAttemptDate should match")
            self.assertDatesEqual(loaded.lastPlaybackInteractionDate, original.lastPlaybackInteractionDate, "lastPlaybackInteractionDate should match")
            XCTAssertEqual(loaded.lastPlaybackInteractionSyncStatus, original.lastPlaybackInteractionSyncStatus, "lastPlaybackInteractionSyncStatus should match")
            self.assertDatesEqual(loaded.lastArchiveInteractionDate, original.lastArchiveInteractionDate, "lastArchiveInteractionDate should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that hasOnlyUuid is NOT persisted (excluded from CodingKeys)
    func testHasOnlyUuidNotPersisted() throws {
        try runWithDataManager { dataManager in
            // Create a podcast first
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            dataManager.save(podcast: podcast)

            let episode = Episode()
            episode.uuid = UUID().uuidString.lowercased()
            episode.podcastUuid = podcast.uuid
            episode.title = "Test Episode"
            episode.addedDate = Date()
            episode.hasOnlyUuid = true  // Set ignored property

            dataManager.save(episode: episode)

            // Load it back - hasOnlyUuid should be default (false)
            guard let loaded = dataManager.findEpisode(uuid: episode.uuid) else {
                XCTFail("Should find saved episode")
                return
            }

            // hasOnlyUuid should be false (not persisted)
            XCTAssertFalse(loaded.hasOnlyUuid, "hasOnlyUuid should NOT be persisted")
        }
    }

    // MARK: - GRDB Record Tests

    /// Dates are stored as Unix timestamps, not GRDB's default Date format.
    /// The legacy read path reads them back with `rs.double(forColumn:)`, so a change
    /// here would silently shift every episode date.
    func testDatesAreEncodedAsUnixTimestamps() throws {
        let episode = createFullyPopulatedEpisode(podcastUuid: "podcast-uuid", podcastId: 1)
        let encoded = try episode.databaseDictionary

        let dates: [String: Date?] = [
            "addedDate": episode.addedDate,
            "lastDownloadAttemptDate": episode.lastDownloadAttemptDate,
            "publishedDate": episode.publishedDate,
            "lastPlaybackInteractionDate": episode.lastPlaybackInteractionDate,
            "lastArchiveInteractionDate": episode.lastArchiveInteractionDate
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
        let encoded = try Episode().databaseDictionary

        for column in ["publishedDate", "lastPlaybackInteractionDate"] {
            XCTAssertEqual(encoded[column], .null, "a nil \(column) should encode as NULL")
        }
    }

    /// These columns are `NOT NULL`, so a nil date is stored as 0 instead of NULL.
    /// The legacy read path turns 0 back into nil.
    func testNilDatesInNotNullColumnsAreEncodedAsZero() throws {
        let encoded = try Episode().databaseDictionary

        for column in ["addedDate", "lastDownloadAttemptDate", "lastArchiveInteractionDate"] {
            XCTAssertEqual(Double.fromDatabaseValue(try XCTUnwrap(encoded[column])), 0, "a nil \(column) should encode as 0")
        }
    }

    func testSavesEpisodeWithNilAddedDate() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createFullyPopulatedEpisode(podcastUuid: podcast.uuid, podcastId: podcast.id)
            episode.addedDate = nil

            dataManager.save(episode: episode)

            let loaded = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
            XCTAssertNil(loaded.addedDate)
        }
    }

    /// A row stored with `addedDate` 0 loads with a nil date. Saving that episode
    /// again has to update the row instead of failing the `NOT NULL` constraint.
    func testUpdatesEpisodeWithNilAddedDate() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createFullyPopulatedEpisode(podcastUuid: podcast.uuid, podcastId: podcast.id)
            dataManager.save(episode: episode)

            episode.addedDate = nil
            episode.title = "Renamed"
            dataManager.save(episode: episode)

            let loaded = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
            XCTAssertEqual(loaded.title, "Renamed")
            XCTAssertNil(loaded.addedDate)
        }
    }

    func testTransientPropertiesAreNotEncoded() throws {
        let episode = createFullyPopulatedEpisode(podcastUuid: "podcast-uuid", podcastId: 1)
        episode.hasOnlyUuid = true

        let encoded = try episode.databaseDictionary

        XCTAssertNil(encoded["hasOnlyUuid"], "hasOnlyUuid should not be encoded")
    }

    func testDecodesRowWrittenByGRDB() throws {
        let dataManager = DataManager.newTestDataManager()
        let podcast = createTestPodcast(dataManager: dataManager)
        let original = createFullyPopulatedEpisode(podcastUuid: podcast.uuid, podcastId: podcast.id)
        dataManager.save(episode: original)

        let decoded = try dataManager.dbQueue.dbPool.read { db in
            try Episode.filter(Episode.Columns.uuid == original.uuid).fetchOne(db)
        }

        let episode = try XCTUnwrap(decoded, "should decode an Episode from its own row")
        XCTAssertEqual(try episode.databaseDictionary, try original.databaseDictionary)
    }

    /// Every property decodes with a fallback, so a row missing columns (an older
    /// schema, or a projection) yields defaults instead of throwing.
    func testDecodesRowWithMissingColumnsUsingDefaults() throws {
        let episode = try Episode(row: ["uuid": "abc"])

        let expected = Episode()
        expected.uuid = "abc"
        XCTAssertEqual(try episode.databaseDictionary, try expected.databaseDictionary)
        XCTAssertNil(episode.lastDownloadAttemptDate)
        XCTAssertNil(episode.lastArchiveInteractionDate)
    }

    func testDecodesRowWithNullColumnsUsingDefaults() throws {
        let columns = try Episode().databaseDictionary.keys
        let row = Row(Dictionary(uniqueKeysWithValues: columns.map { ($0, nil as (any DatabaseValueConvertible)?) }))

        let episode = try Episode(row: row)

        XCTAssertEqual(try episode.databaseDictionary, try Episode().databaseDictionary)
        XCTAssertNil(episode.lastDownloadAttemptDate)
        XCTAssertNil(episode.lastArchiveInteractionDate)
    }

    // MARK: - Helpers

    private func assertDatesEqual(_ date1: Date?, _ date2: Date?, _ message: String, file: StaticString = #file, line: UInt = #line) {
        switch (date1, date2) {
        case (nil, nil):
            // Both nil - equal
            break
        case (nil, _), (_, nil):
            XCTFail("\(message) - one date is nil and the other is not", file: file, line: line)
        case let (d1?, d2?):
            XCTAssertEqual(d1.timeIntervalSince1970, d2.timeIntervalSince1970, accuracy: 0.001, message, file: file, line: line)
        }
    }

    private func createFullyPopulatedEpisode(podcastUuid: String, podcastId: Int64) -> Episode {
        let episode = Episode()
        episode.uuid = UUID().uuidString.lowercased()
        episode.podcastUuid = podcastUuid
        episode.podcast_id = podcastId
        episode.title = "Test Episode Title"
        episode.episodeDescription = "Short description"
        episode.detailedDescription = "Detailed description of the episode"
        episode.addedDate = Date(timeIntervalSince1970: 1700000000)
        episode.lastDownloadAttemptDate = Date(timeIntervalSince1970: 1700000100)
        episode.downloadErrorDetails = "Test error"
        episode.downloadTaskId = "download-task-123"
        episode.downloadUrl = "https://example.com/episode.mp3"
        episode.hlsUrl = "https://example.com/episode.m3u8"
        episode.episodeStatus = DownloadStatus.downloaded.rawValue
        episode.fileType = "audio/mpeg"
        episode.contentType = "audio/mpeg"
        episode.keepEpisode = true
        episode.playedUpTo = 123.45
        episode.duration = 3600.0
        episode.playingStatus = PlayingStatus.inProgress.rawValue
        episode.autoDownloadStatus = AutoDownloadStatus.autoDownloaded.rawValue
        episode.publishedDate = Date(timeIntervalSince1970: 1690000000)
        episode.sizeInBytes = 1024000
        episode.playingStatusModified = 111
        episode.playedUpToModified = 222
        episode.durationModified = 333
        episode.keepEpisodeModified = 444
        episode.starredModified = 555
        episode.playbackErrorDetails = "Playback error"
        episode.cachedFrameCount = 100
        episode.episodeNumber = 5
        episode.seasonNumber = 2
        episode.episodeType = "full"
        episode.archived = true
        episode.archivedModified = 666
        episode.excludeFromEpisodeLimit = true
        episode.deselectedChapters = "1,3,5"
        episode.deselectedChaptersModified = 777
        episode.wasDeleted = false
        episode.lastPlaybackInteractionDate = Date(timeIntervalSince1970: 1700000200)
        episode.lastPlaybackInteractionSyncStatus = SyncStatus.notSynced.rawValue
        episode.lastArchiveInteractionDate = Date(timeIntervalSince1970: 1700000300)
        episode.hasGeneratedTranscript = true
        return episode
    }
}
