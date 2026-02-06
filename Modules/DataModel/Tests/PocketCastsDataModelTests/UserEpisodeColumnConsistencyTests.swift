import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests to ensure the legacy SQL columnNames and GRDB-persisted columns remain in sync.
/// These tests prevent the issue where GRDB might persist a field that the legacy SQL path ignores
/// (or vice versa), causing inconsistent behavior when the feature flag is toggled.
final class UserEpisodeColumnConsistencyTests: DataManagerTestCase {

    /// Access columnNames directly from UserEpisodeDataManager (the source of truth for legacy SQL).
    private var columnNames: Set<String> {
        Set(UserEpisodeDataManager().columnNames)
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
            let columns = try db.columns(in: DataManager.userEpisodeTableName)
            return Set(columns.map { $0.name })
        }

        // The database should have at least all the columns from columnNames
        // (it may have more due to migrations or legacy columns like contentType)
        let missingColumns = columnNames.subtracting(tableColumns)
        XCTAssertTrue(
            missingColumns.isEmpty,
            "Database table is missing columns from columnNames: \(missingColumns)"
        )
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoadPreservesAllFields() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let original = self.createFullyPopulatedUserEpisode()

            // Save using the current implementation (respects feature flag)
            dataManager.save(episode: original)

            // Load it back
            guard let loaded = dataManager.findUserEpisode(uuid: original.uuid) else {
                XCTFail("\(implementationName): Should be able to load saved episode")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "\(implementationName): uuid should match")
            XCTAssertEqual(loaded.title, original.title, "\(implementationName): title should match")
            XCTAssertEqual(loaded.duration, original.duration, "\(implementationName): duration should match")
            XCTAssertEqual(loaded.playedUpTo, original.playedUpTo, "\(implementationName): playedUpTo should match")
            XCTAssertEqual(loaded.playingStatus, original.playingStatus, "\(implementationName): playingStatus should match")
            XCTAssertEqual(loaded.episodeStatus, original.episodeStatus, "\(implementationName): episodeStatus should match")
            XCTAssertEqual(loaded.uploadStatus, original.uploadStatus, "\(implementationName): uploadStatus should match")
            XCTAssertEqual(loaded.autoDownloadStatus, original.autoDownloadStatus, "\(implementationName): autoDownloadStatus should match")
            XCTAssertEqual(loaded.sizeInBytes, original.sizeInBytes, "\(implementationName): sizeInBytes should match")
            XCTAssertEqual(loaded.fileType, original.fileType, "\(implementationName): fileType should match")
            XCTAssertEqual(loaded.downloadUrl, original.downloadUrl, "\(implementationName): downloadUrl should match")
            XCTAssertEqual(loaded.downloadTaskId, original.downloadTaskId, "\(implementationName): downloadTaskId should match")
            XCTAssertEqual(loaded.uploadTaskId, original.uploadTaskId, "\(implementationName): uploadTaskId should match")
            XCTAssertEqual(loaded.imageUrl, original.imageUrl, "\(implementationName): imageUrl should match")
            XCTAssertEqual(loaded.imageColor, original.imageColor, "\(implementationName): imageColor should match")
            XCTAssertEqual(loaded.hasCustomImage, original.hasCustomImage, "\(implementationName): hasCustomImage should match")
            XCTAssertEqual(loaded.cachedFrameCount, original.cachedFrameCount, "\(implementationName): cachedFrameCount should match")
            XCTAssertEqual(loaded.playingStatusModified, original.playingStatusModified, "\(implementationName): playingStatusModified should match")
            XCTAssertEqual(loaded.playedUpToModified, original.playedUpToModified, "\(implementationName): playedUpToModified should match")
            XCTAssertEqual(loaded.titleModified, original.titleModified, "\(implementationName): titleModified should match")
            XCTAssertEqual(loaded.durationModified, original.durationModified, "\(implementationName): durationModified should match")
            XCTAssertEqual(loaded.imageModified, original.imageModified, "\(implementationName): imageModified should match")
            XCTAssertEqual(loaded.imageColorModified, original.imageColorModified, "\(implementationName): imageColorModified should match")
            XCTAssertEqual(loaded.downloadErrorDetails, original.downloadErrorDetails, "\(implementationName): downloadErrorDetails should match")
            XCTAssertEqual(loaded.playbackErrorDetails, original.playbackErrorDetails, "\(implementationName): playbackErrorDetails should match")
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that contentType is NOT persisted by save() but IS persisted by saveContentType()
    func testContentTypeNotPersistedBySave() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let episode = UserEpisode()
            episode.uuid = UUID().uuidString
            episode.title = "ContentType Test"
            episode.addedDate = Date()
            episode.contentType = "audio/mpeg"  // Set contentType

            dataManager.save(episode: episode)

            // Load it back - contentType should NOT be saved by save()
            guard let loaded = dataManager.findUserEpisode(uuid: episode.uuid) else {
                XCTFail("\(implementationName): Should find saved episode")
                return
            }

            // contentType should be nil because save() doesn't persist it
            XCTAssertNil(loaded.contentType, "\(implementationName): contentType should NOT be persisted by save() - use saveContentType() instead")
        }
    }

    func testContentTypePersistedBySaveContentType() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let episode = UserEpisode()
            episode.uuid = UUID().uuidString
            episode.title = "ContentType Test"
            episode.addedDate = Date()
            dataManager.save(episode: episode)

            // Use the dedicated method to save contentType
            dataManager.saveEpisode(contentType: "audio/mpeg", episode: episode)

            guard let loaded = dataManager.findUserEpisode(uuid: episode.uuid) else {
                XCTFail("\(implementationName): Should find saved episode")
                return
            }

            XCTAssertEqual(loaded.contentType, "audio/mpeg", "\(implementationName): contentType should be persisted by saveContentType()")
        }
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
        episode.addedDate = Date()
        episode.lastDownloadAttemptDate = Date()
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
        episode.publishedDate = Date()
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
