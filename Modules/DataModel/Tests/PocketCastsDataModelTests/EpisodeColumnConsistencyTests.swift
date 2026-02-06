import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests to ensure the legacy SQL columnNames and GRDB-persisted columns remain in sync.
/// These tests prevent the issue where GRDB might persist a field that the legacy SQL path ignores
/// (or vice versa), causing inconsistent behavior when the feature flag is toggled.
final class EpisodeColumnConsistencyTests: DataManagerTestCase {

    /// Access columnNames directly from EpisodeDataManager (the source of truth for legacy SQL).
    private var columnNames: Set<String> {
        Set(EpisodeDataManager().columnNames)
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
            let columns = try db.columns(in: DataManager.episodeTableName)
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
            // Create a podcast first since episodes require a parent podcast
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString.lowercased()
            podcast.title = "Test Podcast"
            podcast.addedDate = Date()
            dataManager.save(podcast: podcast)

            let original = self.createFullyPopulatedEpisode(podcastUuid: podcast.uuid)

            // Save using the current implementation (respects feature flag)
            dataManager.save(episode: original)

            // Load it back
            guard let loaded = dataManager.findEpisode(uuid: original.uuid) else {
                XCTFail("\(implementationName): Should be able to load saved episode")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "\(implementationName): uuid should match")
            XCTAssertEqual(loaded.podcastUuid, original.podcastUuid, "\(implementationName): podcastUuid should match")
            XCTAssertEqual(loaded.title, original.title, "\(implementationName): title should match")
            XCTAssertEqual(loaded.episodeDescription, original.episodeDescription, "\(implementationName): episodeDescription should match")
            XCTAssertEqual(loaded.detailedDescription, original.detailedDescription, "\(implementationName): detailedDescription should match")
            XCTAssertEqual(loaded.duration, original.duration, "\(implementationName): duration should match")
            XCTAssertEqual(loaded.playedUpTo, original.playedUpTo, "\(implementationName): playedUpTo should match")
            XCTAssertEqual(loaded.playingStatus, original.playingStatus, "\(implementationName): playingStatus should match")
            XCTAssertEqual(loaded.episodeStatus, original.episodeStatus, "\(implementationName): episodeStatus should match")
            XCTAssertEqual(loaded.autoDownloadStatus, original.autoDownloadStatus, "\(implementationName): autoDownloadStatus should match")
            XCTAssertEqual(loaded.sizeInBytes, original.sizeInBytes, "\(implementationName): sizeInBytes should match")
            XCTAssertEqual(loaded.fileType, original.fileType, "\(implementationName): fileType should match")
            XCTAssertEqual(loaded.contentType, original.contentType, "\(implementationName): contentType should match")
            XCTAssertEqual(loaded.downloadUrl, original.downloadUrl, "\(implementationName): downloadUrl should match")
            XCTAssertEqual(loaded.downloadTaskId, original.downloadTaskId, "\(implementationName): downloadTaskId should match")
            XCTAssertEqual(loaded.keepEpisode, original.keepEpisode, "\(implementationName): keepEpisode should match")
            XCTAssertEqual(loaded.cachedFrameCount, original.cachedFrameCount, "\(implementationName): cachedFrameCount should match")
            XCTAssertEqual(loaded.playingStatusModified, original.playingStatusModified, "\(implementationName): playingStatusModified should match")
            XCTAssertEqual(loaded.playedUpToModified, original.playedUpToModified, "\(implementationName): playedUpToModified should match")
            XCTAssertEqual(loaded.durationModified, original.durationModified, "\(implementationName): durationModified should match")
            XCTAssertEqual(loaded.keepEpisodeModified, original.keepEpisodeModified, "\(implementationName): keepEpisodeModified should match")
            XCTAssertEqual(loaded.starredModified, original.starredModified, "\(implementationName): starredModified should match")
            XCTAssertEqual(loaded.downloadErrorDetails, original.downloadErrorDetails, "\(implementationName): downloadErrorDetails should match")
            XCTAssertEqual(loaded.playbackErrorDetails, original.playbackErrorDetails, "\(implementationName): playbackErrorDetails should match")
            XCTAssertEqual(loaded.episodeNumber, original.episodeNumber, "\(implementationName): episodeNumber should match")
            XCTAssertEqual(loaded.seasonNumber, original.seasonNumber, "\(implementationName): seasonNumber should match")
            XCTAssertEqual(loaded.episodeType, original.episodeType, "\(implementationName): episodeType should match")
            XCTAssertEqual(loaded.archived, original.archived, "\(implementationName): archived should match")
            XCTAssertEqual(loaded.archivedModified, original.archivedModified, "\(implementationName): archivedModified should match")
            XCTAssertEqual(loaded.excludeFromEpisodeLimit, original.excludeFromEpisodeLimit, "\(implementationName): excludeFromEpisodeLimit should match")
            XCTAssertEqual(loaded.deselectedChapters, original.deselectedChapters, "\(implementationName): deselectedChapters should match")
            XCTAssertEqual(loaded.deselectedChaptersModified, original.deselectedChaptersModified, "\(implementationName): deselectedChaptersModified should match")
            XCTAssertEqual(loaded.wasDeleted, original.wasDeleted, "\(implementationName): wasDeleted should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that hasOnlyUuid is NOT persisted (marked with @GRDBIgnore)
    func testHasOnlyUuidNotPersisted() throws {
        try runWithBothImplementations { dataManager, implementationName in
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
                XCTFail("\(implementationName): Should find saved episode")
                return
            }

            // hasOnlyUuid should be false (not persisted)
            XCTAssertFalse(loaded.hasOnlyUuid, "\(implementationName): hasOnlyUuid should NOT be persisted")
        }
    }

    // MARK: - Helpers

    private func createFullyPopulatedEpisode(podcastUuid: String) -> Episode {
        let episode = Episode()
        episode.uuid = UUID().uuidString.lowercased()
        episode.podcastUuid = podcastUuid
        episode.title = "Test Episode Title"
        episode.episodeDescription = "Short description"
        episode.detailedDescription = "Detailed description of the episode"
        episode.addedDate = Date()
        episode.lastDownloadAttemptDate = Date()
        episode.downloadErrorDetails = "Test error"
        episode.downloadTaskId = "download-task-123"
        episode.downloadUrl = "https://example.com/episode.mp3"
        episode.episodeStatus = DownloadStatus.downloaded.rawValue
        episode.fileType = "audio/mpeg"
        episode.contentType = "audio/mpeg"
        episode.keepEpisode = true
        episode.playedUpTo = 123.45
        episode.duration = 3600.0
        episode.playingStatus = PlayingStatus.inProgress.rawValue
        episode.autoDownloadStatus = AutoDownloadStatus.autoDownloaded.rawValue
        episode.publishedDate = Date()
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
        episode.archived = false
        episode.archivedModified = 666
        episode.excludeFromEpisodeLimit = true
        episode.deselectedChapters = "1,3,5"
        episode.deselectedChaptersModified = 777
        episode.wasDeleted = false
        return episode
    }
}
