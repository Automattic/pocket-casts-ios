import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for UserEpisodeDataManager using the public API.
final class UserEpisodeDataManagerTests: DataManagerTestCase {

    // MARK: - findUserEpisode Tests

    func testFindUserEpisodeByUuidReturnsUserEpisode() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "test-user-episode-uuid", title: "Test Episode", dataManager: dataManager)

            let found = dataManager.findUserEpisode(uuid: "test-user-episode-uuid")

            XCTAssertNotNil(found, "Should find user episode")
            XCTAssertEqual(found?.uuid, episode.uuid, "UUID should match")
            XCTAssertEqual(found?.title, episode.title, "Title should match")
        }
    }

    func testFindUserEpisodeByUuidReturnsNilForNonExistent() throws {
        try runWithDataManager { dataManager in
            let found = dataManager.findUserEpisode(uuid: "non-existent-uuid")

            XCTAssertNil(found, "Should not find non-existent user episode")
        }
    }

    // MARK: - findUserEpisode(uploadTaskId:) Tests

    func testFindUserEpisodeByUploadTaskIdReturnsUserEpisode() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uploadTaskId: "upload-task-123", dataManager: dataManager)

            let found = dataManager.findUserEpisode(uploadTaskId: "upload-task-123")

            XCTAssertNotNil(found, "Should find user episode by upload task ID")
            XCTAssertEqual(found?.uuid, episode.uuid, "UUID should match")
        }
    }

    func testFindUserEpisodeByUploadTaskIdReturnsNilForNonExistent() throws {
        try runWithDataManager { dataManager in
            let found = dataManager.findUserEpisode(uploadTaskId: "non-existent-task")

            XCTAssertNil(found, "Should not find user episode with non-existent upload task ID")
        }
    }

    // MARK: - findBaseEpisode(downloadTaskId:) Tests

    func testFindBaseEpisodeByDownloadTaskIdReturnsUserEpisode() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(downloadTaskId: "download-task-123", dataManager: dataManager)

            let found = dataManager.findBaseEpisode(downloadTaskId: "download-task-123")

            XCTAssertNotNil(found, "Should find base episode by download task ID")
            XCTAssertEqual(found?.uuid, episode.uuid, "UUID should match")
        }
    }

    func testFindBaseEpisodeByDownloadTaskIdReturnsNilForNonExistent() throws {
        try runWithDataManager { dataManager in
            let found = dataManager.findBaseEpisode(downloadTaskId: "non-existent-task")

            XCTAssertNil(found, "Should not find base episode with non-existent download task ID")
        }
    }

    // MARK: - allUserEpisodes Tests

    func testAllUserEpisodesReturnsAllEpisodes() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Episode 1", dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Episode 2", dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Episode 3", dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .newestToOldest)

            XCTAssertEqual(episodes.count, 3, "Should return all 3 episodes")
        }
    }

    func testAllUserEpisodesExcludesDeletePending() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Active", uploadStatus: UploadStatus.notUploaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Delete Pending", uploadStatus: UploadStatus.deleteFromCloudPending.rawValue, dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .newestToOldest)

            XCTAssertTrue(episodes.allSatisfy { $0.uploadStatus != UploadStatus.deleteFromCloudPending.rawValue }, "Should exclude delete pending episodes")
        }
    }

    func testAllUserEpisodesRespectsLimit() throws {
        try runWithDataManager { dataManager in
            for i in 0..<10 {
                _ = self.createTestUserEpisode(title: "Episode \(i)", dataManager: dataManager)
            }

            let episodes = dataManager.allUserEpisodes(sortedBy: .newestToOldest, limit: 5)

            XCTAssertEqual(episodes.count, 5, "Should respect limit")
        }
    }

    func testAllUserEpisodesSortsNewestToOldest() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Oldest", addedDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Newest", addedDate: Date(), dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .newestToOldest)

            if let first = episodes.first, let last = episodes.last {
                XCTAssertTrue(first.addedDate! >= last.addedDate!, "Should be sorted newest to oldest")
            }
        }
    }

    func testAllUserEpisodesSortsOldestToNewest() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Oldest", addedDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Newest", addedDate: Date(), dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .oldestToNewest)

            if episodes.count >= 2 {
                XCTAssertTrue(episodes.first!.addedDate! <= episodes.last!.addedDate!, "Should be sorted oldest to newest")
            }
        }
    }

    func testAllUserEpisodesSortsByTitleAtoZ() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Zebra", dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Apple", dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Banana", dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .titleAtoZ)

            let titles = episodes.map { $0.title }
            XCTAssertEqual(titles, ["Apple", "Banana", "Zebra"], "Should be sorted A to Z")
        }
    }

    func testAllUserEpisodesSortsByTitleZtoA() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Zebra", dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Apple", dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Banana", dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .titleZtoA)

            let titles = episodes.map { $0.title }
            XCTAssertEqual(titles, ["Zebra", "Banana", "Apple"], "Should be sorted Z to A")
        }
    }

    func testAllUserEpisodesSortsByDurationShortestToLongest() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Long", duration: 7200, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Short", duration: 1800, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Medium", duration: 3600, dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .shortestToLongest)

            if episodes.count >= 2 {
                XCTAssertTrue(episodes.first!.duration <= episodes.last!.duration, "Should be sorted shortest to longest")
            }
        }
    }

    func testAllUserEpisodesSortsByDurationLongestToShortest() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Long", duration: 7200, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Short", duration: 1800, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Medium", duration: 3600, dataManager: dataManager)

            let episodes = dataManager.allUserEpisodes(sortedBy: .longestToShortest)

            if episodes.count >= 2 {
                XCTAssertTrue(episodes.first!.duration >= episodes.last!.duration, "Should be sorted longest to shortest")
            }
        }
    }

    // MARK: - allUserEpisodesDownloaded Tests

    func testAllUserEpisodesDownloadedReturnsOnlyDownloaded() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Downloaded", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Not Downloaded", episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            let episodes = dataManager.allUserEpisodesDownloaded(sortedBy: .newestToOldest)

            XCTAssertTrue(episodes.allSatisfy { $0.episodeStatus == DownloadStatus.downloaded.rawValue }, "Should only return downloaded episodes")
        }
    }

    func testAllUserEpisodesDownloadedRespectsLimit() throws {
        try runWithDataManager { dataManager in
            for i in 0..<10 {
                _ = self.createTestUserEpisode(title: "Downloaded \(i)", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            }

            let episodes = dataManager.allUserEpisodesDownloaded(sortedBy: .newestToOldest, limit: 5)

            XCTAssertEqual(episodes.count, 5, "Should respect limit")
        }
    }

    // MARK: - findUserEpisodesWithUploadStatus Tests

    func testFindUserEpisodesWithUploadStatusReturnsMatchingStatus() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Uploaded", uploadStatus: UploadStatus.uploaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Not Uploaded", uploadStatus: UploadStatus.notUploaded.rawValue, dataManager: dataManager)

            let episodes = dataManager.findUserEpisodesWithUploadStatus(.uploaded)

            XCTAssertTrue(episodes.allSatisfy { $0.uploadStatus == UploadStatus.uploaded.rawValue }, "Should only return uploaded episodes")
        }
    }

    // MARK: - unsyncedUserEpisodes Tests

    func testUnsyncedUserEpisodesReturnsEpisodesWithModifiedFields() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Unsynced", playingStatusModified: 1, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Synced", playingStatusModified: 0, dataManager: dataManager)

            let episodes = dataManager.unsyncedUserEpisodes()

            XCTAssertTrue(episodes.contains { $0.title == "Unsynced" }, "Should include unsynced episode")
        }
    }

    func testUnsyncedUserEpisodesChecksMultipleModifiedFields() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Title Modified", titleModified: 1, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Playing Modified", playingStatusModified: 1, dataManager: dataManager)

            let episodes = dataManager.unsyncedUserEpisodes()

            XCTAssertGreaterThanOrEqual(episodes.count, 2, "Should detect all modified fields")
        }
    }

    // MARK: - frameCount Tests

    func testSaveAndFindFrameCount() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(title: "Episode with frames", dataManager: dataManager)

            dataManager.saveFrameCount(episode: episode, frameCount: 12345)

            let frameCount = dataManager.findFrameCount(episode: episode)
            XCTAssertEqual(frameCount, 12345, "Frame count should match")
        }
    }

    func testFindFrameCountReturnsZeroForNonExistent() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(title: "Episode", dataManager: dataManager)

            // Don't set frame count
            let frameCount = dataManager.findFrameCount(episode: episode)

            XCTAssertEqual(frameCount, 0, "Should return 0 for episode without frame count")
        }
    }

    // MARK: - removeOrphanedUserEpisodes Tests

    func testRemoveOrphanedUserEpisodesRemovesOrphanedEpisodes() throws {
        try runWithDataManager { dataManager in
            let orphaned = self.createTestUserEpisode(
                title: "Orphaned",
                episodeStatus: DownloadStatus.notDownloaded.rawValue,
                uploadStatus: UploadStatus.notUploaded.rawValue,
                dataManager: dataManager
            )

            dataManager.removeOrphanedUserEpisodes()

            let found = dataManager.findUserEpisode(uuid: orphaned.uuid)
            XCTAssertNil(found, "Should remove orphaned episode")
        }
    }

    func testRemoveOrphanedUserEpisodesKeepsDownloadedEpisodes() throws {
        try runWithDataManager { dataManager in
            let downloaded = self.createTestUserEpisode(
                title: "Downloaded",
                episodeStatus: DownloadStatus.downloaded.rawValue,
                uploadStatus: UploadStatus.notUploaded.rawValue,
                dataManager: dataManager
            )

            dataManager.removeOrphanedUserEpisodes()

            let found = dataManager.findUserEpisode(uuid: downloaded.uuid)
            XCTAssertNotNil(found, "Should keep downloaded episode")
        }
    }

    func testRemoveOrphanedUserEpisodesKeepsUploadedEpisodes() throws {
        try runWithDataManager { dataManager in
            let uploaded = self.createTestUserEpisode(
                title: "Uploaded",
                episodeStatus: DownloadStatus.notDownloaded.rawValue,
                uploadStatus: UploadStatus.uploaded.rawValue,
                dataManager: dataManager
            )

            dataManager.removeOrphanedUserEpisodes()

            let found = dataManager.findUserEpisode(uuid: uploaded.uuid)
            XCTAssertNotNil(found, "Should keep uploaded episode")
        }
    }

    // MARK: - delete Tests

    func testDeleteRemovesUserEpisode() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(title: "To Delete", dataManager: dataManager)

            dataManager.delete(userEpisodeUuid: episode.uuid)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertNil(found, "Should delete user episode")
        }
    }

    func testDeleteUserEpisodesRemovesMultipleEpisodes() throws {
        try runWithDataManager { dataManager in
            let episode1 = self.createTestUserEpisode(title: "To Delete 1", dataManager: dataManager)
            let episode2 = self.createTestUserEpisode(title: "To Delete 2", dataManager: dataManager)
            let episode3 = self.createTestUserEpisode(title: "To Keep", dataManager: dataManager)

            dataManager.deleteUserEpisodes(userEpisodeUuids: [episode1.uuid, episode2.uuid])

            XCTAssertNil(dataManager.findUserEpisode(uuid: episode1.uuid), "Should delete episode 1")
            XCTAssertNil(dataManager.findUserEpisode(uuid: episode2.uuid), "Should delete episode 2")
            XCTAssertNotNil(dataManager.findUserEpisode(uuid: episode3.uuid), "Should keep episode 3")
        }
    }

    // MARK: - clearDownloadTaskId Tests

    func testClearDownloadTaskIdClearsTaskId() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(downloadTaskId: "task-123", dataManager: dataManager)

            dataManager.clearDownloadTaskId(episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertNil(found?.downloadTaskId, "Download task ID should be cleared")
        }
    }

    // MARK: - clearUploadTaskId Tests

    func testClearUploadTaskIdClearsTaskId() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uploadTaskId: "task-123", dataManager: dataManager)

            dataManager.clearUploadTaskId(episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertNil(found?.uploadTaskId, "Upload task ID should be cleared")
        }
    }

    // MARK: - downloadedEpisodeCount Tests (includes UserEpisodes)

    func testDownloadedEpisodeCountIncludesUserEpisodes() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Downloaded 1", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Downloaded 2", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Not Downloaded", episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            let count = dataManager.downloadedEpisodeCount()

            XCTAssertGreaterThanOrEqual(count, 2, "Should count downloaded user episodes")
        }
    }

    func testDownloadedEpisodeCountReturnsZeroWhenNoDownloadedUserEpisodes() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Not Downloaded", episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            let count = dataManager.downloadedEpisodeCount()

            XCTAssertEqual(count, 0, "Should return 0 when no downloaded episodes")
        }
    }

    // MARK: - save Tests (PersistableRecord API)

    func testSaveInsertsNewUserEpisodeWithAllFields() throws {
        try runWithDataManager { dataManager in
            let episode = UserEpisode()
            episode.uuid = "save-test-uuid"
            episode.title = "Save Test Episode"
            episode.addedDate = Date(timeIntervalSince1970: 1000000)
            episode.duration = 7200
            episode.playedUpTo = 300.5
            episode.playingStatus = PlayingStatus.inProgress.rawValue
            episode.episodeStatus = DownloadStatus.downloaded.rawValue
            episode.uploadStatus = UploadStatus.uploaded.rawValue
            episode.autoDownloadStatus = AutoDownloadStatus.autoDownloaded.rawValue
            episode.sizeInBytes = 1024000
            episode.fileType = "audio/mpeg"
            episode.hasCustomImage = true
            episode.imageColor = 5

            dataManager.save(episode: episode)

            let found = dataManager.findUserEpisode(uuid: "save-test-uuid")
            XCTAssertNotNil(found, "Should find saved user episode")
            XCTAssertEqual(found?.uuid, "save-test-uuid", "UUID should match")
            XCTAssertEqual(found?.title, "Save Test Episode", "Title should match")
            XCTAssertEqual(found?.duration, 7200, "Duration should match")
            XCTAssertEqual(found?.playedUpTo, 300.5, "playedUpTo should match")
            XCTAssertEqual(found?.playingStatus, PlayingStatus.inProgress.rawValue, "playingStatus should match")
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.downloaded.rawValue, "episodeStatus should match")
            XCTAssertEqual(found?.uploadStatus, UploadStatus.uploaded.rawValue, "uploadStatus should match")
            XCTAssertEqual(found?.autoDownloadStatus, AutoDownloadStatus.autoDownloaded.rawValue, "autoDownloadStatus should match")
            XCTAssertEqual(found?.sizeInBytes, 1024000, "sizeInBytes should match")
            XCTAssertEqual(found?.fileType, "audio/mpeg", "fileType should match")
            XCTAssertEqual(found?.hasCustomImage, true, "hasCustomImage should match")
            XCTAssertEqual(found?.imageColor, 5, "imageColor should match")
        }
    }

    func testSaveUpdatesExistingUserEpisode() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "update-test-uuid", title: "Original Title", duration: 3600, dataManager: dataManager)

            // Update fields
            episode.title = "Updated Title"
            episode.duration = 7200
            episode.playedUpTo = 500.0
            episode.playingStatus = PlayingStatus.completed.rawValue
            episode.episodeStatus = DownloadStatus.downloaded.rawValue
            dataManager.save(episode: episode)

            let found = dataManager.findUserEpisode(uuid: "update-test-uuid")
            XCTAssertEqual(found?.title, "Updated Title", "Title should be updated")
            XCTAssertEqual(found?.duration, 7200, "Duration should be updated")
            XCTAssertEqual(found?.playedUpTo, 500.0, "playedUpTo should be updated")
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "playingStatus should be updated")
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.downloaded.rawValue, "episodeStatus should be updated")
        }
    }

    func testSaveGeneratesIdIfZero() throws {
        try runWithDataManager { dataManager in
            let episode = UserEpisode()
            episode.uuid = "id-test-uuid"
            episode.title = "ID Test Episode"
            episode.addedDate = Date()
            episode.id = 0

            dataManager.save(episode: episode)

            XCTAssertNotEqual(episode.id, 0, "ID should be generated")

            let found = dataManager.findUserEpisode(uuid: "id-test-uuid")
            XCTAssertNotNil(found, "Should find episode with generated ID")
            XCTAssertNotEqual(found?.id, 0, "Found episode should have non-zero ID")
        }
    }

    func testSavePreservesModifiedFlags() throws {
        try runWithDataManager { dataManager in
            let episode = UserEpisode()
            episode.uuid = "modified-test-uuid"
            episode.title = "Modified Flags Test"
            episode.addedDate = Date()
            episode.playingStatusModified = 12345
            episode.playedUpToModified = 67890
            episode.titleModified = 11111
            episode.durationModified = 22222
            episode.imageModified = 33333
            episode.imageColorModified = 44444

            dataManager.save(episode: episode)

            let found = dataManager.findUserEpisode(uuid: "modified-test-uuid")
            XCTAssertEqual(found?.playingStatusModified, 12345, "playingStatusModified should be preserved")
            XCTAssertEqual(found?.playedUpToModified, 67890, "playedUpToModified should be preserved")
            XCTAssertEqual(found?.titleModified, 11111, "titleModified should be preserved")
            XCTAssertEqual(found?.durationModified, 22222, "durationModified should be preserved")
            XCTAssertEqual(found?.imageModified, 33333, "imageModified should be preserved")
            XCTAssertEqual(found?.imageColorModified, 44444, "imageColorModified should be preserved")
        }
    }

    func testSavePreservesOptionalStrings() throws {
        try runWithDataManager { dataManager in
            let episode = UserEpisode()
            episode.uuid = "optional-test-uuid"
            episode.title = "Optional Strings Test"
            episode.addedDate = Date()
            episode.downloadUrl = "https://example.com/episode.mp3"
            episode.downloadTaskId = "download-task-123"
            episode.uploadTaskId = "upload-task-456"
            episode.imageUrl = "https://example.com/image.jpg"
            episode.downloadErrorDetails = "Test error"
            episode.playbackErrorDetails = "Playback error"

            dataManager.save(episode: episode)

            let found = dataManager.findUserEpisode(uuid: "optional-test-uuid")
            XCTAssertEqual(found?.downloadUrl, "https://example.com/episode.mp3", "downloadUrl should be preserved")
            XCTAssertEqual(found?.downloadTaskId, "download-task-123", "downloadTaskId should be preserved")
            XCTAssertEqual(found?.uploadTaskId, "upload-task-456", "uploadTaskId should be preserved")
            XCTAssertEqual(found?.imageUrl, "https://example.com/image.jpg", "imageUrl should be preserved")
            XCTAssertEqual(found?.downloadErrorDetails, "Test error", "downloadErrorDetails should be preserved")
            XCTAssertEqual(found?.playbackErrorDetails, "Playback error", "playbackErrorDetails should be preserved")
        }
    }

    // MARK: - bulkSave Tests (PersistableRecord API)

    func testBulkSaveUpdatesExistingUserEpisodes() throws {
        try runWithDataManager { dataManager in
            let episode1 = self.createTestUserEpisode(uuid: "bulk-update-1", title: "Episode 1", dataManager: dataManager)
            let episode2 = self.createTestUserEpisode(uuid: "bulk-update-2", title: "Episode 2", dataManager: dataManager)

            // Update the episodes
            episode1.title = "Episode 1 Updated"
            episode1.playingStatus = PlayingStatus.completed.rawValue
            episode2.title = "Episode 2 Updated"
            episode2.playingStatus = PlayingStatus.inProgress.rawValue

            dataManager.bulkSave(episodes: [episode1, episode2])

            let found1 = dataManager.findUserEpisode(uuid: "bulk-update-1")
            let found2 = dataManager.findUserEpisode(uuid: "bulk-update-2")

            XCTAssertEqual(found1?.title, "Episode 1 Updated", "Episode 1 title should be updated")
            XCTAssertEqual(found1?.playingStatus, PlayingStatus.completed.rawValue, "Episode 1 playingStatus should be updated")
            XCTAssertEqual(found2?.title, "Episode 2 Updated", "Episode 2 title should be updated")
            XCTAssertEqual(found2?.playingStatus, PlayingStatus.inProgress.rawValue, "Episode 2 playingStatus should be updated")
        }
    }

    func testBulkSaveMixedInsertAndUpdate() throws {
        try runWithDataManager { dataManager in
            // Create one existing episode
            let existingEpisode = self.createTestUserEpisode(uuid: "existing-uuid", title: "Existing Episode", dataManager: dataManager)

            // Create a new episode
            let newEpisode = UserEpisode()
            newEpisode.uuid = "new-uuid"
            newEpisode.title = "New Episode"
            newEpisode.addedDate = Date()

            // Update existing episode
            existingEpisode.title = "Existing Episode Updated"

            dataManager.bulkSave(episodes: [existingEpisode, newEpisode])

            let foundExisting = dataManager.findUserEpisode(uuid: "existing-uuid")
            let foundNew = dataManager.findUserEpisode(uuid: "new-uuid")

            XCTAssertEqual(foundExisting?.title, "Existing Episode Updated", "Existing episode should be updated")
            XCTAssertNotNil(foundNew, "New episode should be inserted")
            XCTAssertEqual(foundNew?.title, "New Episode", "New episode title should match")
        }
    }

    func testBulkSaveSavesMultipleUserEpisodes() throws {
        try runWithDataManager { dataManager in
            var episodes = [UserEpisode]()
            for i in 0..<5 {
                let episode = UserEpisode()
                episode.uuid = "bulk-user-\(i)"
                episode.title = "Bulk Episode \(i)"
                episode.addedDate = Date()
                episodes.append(episode)
            }

            dataManager.bulkSave(episodes: episodes)

            for i in 0..<5 {
                let found = dataManager.findUserEpisode(uuid: "bulk-user-\(i)")
                XCTAssertNotNil(found, "Should find bulk saved user episode \(i)")
                XCTAssertEqual(found?.title, "Bulk Episode \(i)", "Title should match for episode \(i)")
            }
        }
    }

    // MARK: - bulkMarkAsPlayed Tests

    func testBulkMarkAsPlayedMarksUserEpisodesAsPlayed() throws {
        try runWithDataManager { dataManager in
            let episode1 = self.createTestUserEpisode(uuid: "user-ep-1", title: "Episode 1", playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)
            let episode2 = self.createTestUserEpisode(uuid: "user-ep-2", title: "Episode 2", playingStatus: PlayingStatus.inProgress.rawValue, dataManager: dataManager)

            dataManager.bulkMarkAsPlayed(episodes: [episode1, episode2], updateSyncFlag: false)

            let found1 = dataManager.findUserEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findUserEpisode(uuid: episode2.uuid)

            XCTAssertEqual(found1?.playingStatus, PlayingStatus.completed.rawValue, "Episode 1 should be marked as played")
            XCTAssertEqual(found2?.playingStatus, PlayingStatus.completed.rawValue, "Episode 2 should be marked as played")
        }
    }

    func testBulkMarkAsPlayedSkipsAlreadyPlayedEpisodes() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "already-played", title: "Already Played", playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)

            // Should not crash or cause issues
            dataManager.bulkMarkAsPlayed(episodes: [episode], updateSyncFlag: false)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "Should still be played")
        }
    }

    // MARK: - bulkMarkAsUnPlayed Tests

    func testBulkMarkAsUnPlayedMarksUserEpisodesAsNotPlayed() throws {
        try runWithDataManager { dataManager in
            let episode1 = self.createTestUserEpisode(uuid: "user-ep-1", title: "Episode 1", playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)
            let episode2 = self.createTestUserEpisode(uuid: "user-ep-2", title: "Episode 2", playingStatus: PlayingStatus.inProgress.rawValue, dataManager: dataManager)

            dataManager.bulkMarkAsUnPlayed(baseEpisodes: [episode1, episode2], updateSyncFlag: false)

            let found1 = dataManager.findUserEpisode(uuid: episode1.uuid)
            let found2 = dataManager.findUserEpisode(uuid: episode2.uuid)

            XCTAssertEqual(found1?.playingStatus, PlayingStatus.notPlayed.rawValue, "Episode 1 should be marked as not played")
            XCTAssertEqual(found2?.playingStatus, PlayingStatus.notPlayed.rawValue, "Episode 2 should be marked as not played")
        }
    }

    func testBulkMarkAsUnPlayedResetsPlayedUpTo() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "user-ep-1", title: "Episode 1", playingStatus: PlayingStatus.inProgress.rawValue, playedUpTo: 300.0, dataManager: dataManager)

            dataManager.bulkMarkAsUnPlayed(baseEpisodes: [episode], updateSyncFlag: false)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playedUpTo, 0, "playedUpTo should be reset to 0")
        }
    }

    // MARK: - saveEpisode playingStatus Tests

    func testSaveEpisodePlayingStatusUpdatesStatus() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "status-ep", playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            dataManager.saveEpisode(playingStatus: .completed, episode: episode, updateSyncFlag: false)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playingStatus, PlayingStatus.completed.rawValue, "Playing status should be updated")
        }
    }

    func testSaveEpisodePlayingStatusUpdatesSyncFlag() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "status-ep", playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)

            dataManager.saveEpisode(playingStatus: .completed, episode: episode, updateSyncFlag: true)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertGreaterThan(found?.playingStatusModified ?? 0, 0, "Playing status modified should be set")
        }
    }

    // MARK: - saveEpisode playedUpTo Tests

    func testSaveEpisodePlayedUpToUpdatesPosition() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "played-ep", dataManager: dataManager)

            dataManager.saveEpisode(playedUpTo: 150.5, episode: episode, updateSyncFlag: false)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playedUpTo, 150.5, "Played up to should be updated")
        }
    }

    // MARK: - saveEpisode uploadStatus Tests

    func testSaveEpisodeUploadStatusUpdatesStatus() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "upload-ep", uploadStatus: UploadStatus.notUploaded.rawValue, dataManager: dataManager)

            dataManager.saveEpisode(uploadStatus: .uploaded, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.uploadStatus, UploadStatus.uploaded.rawValue, "Upload status should be updated")
        }
    }

    // MARK: - saveEpisode downloadStatus Tests

    func testSaveEpisodeDownloadStatusUpdatesStatus() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "download-ep", episodeStatus: DownloadStatus.notDownloaded.rawValue, dataManager: dataManager)

            dataManager.saveEpisode(downloadStatus: .downloaded, downloadTaskId: nil, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.downloaded.rawValue, "Download status should be updated")
        }
    }

    func testSaveEpisodeDownloadStatusWithSizeUpdates() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "download-ep", dataManager: dataManager)

            dataManager.saveEpisode(downloadStatus: .downloaded, sizeInBytes: 1024000, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.sizeInBytes, 1024000, "Size should be updated")
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.downloaded.rawValue, "Download status should be updated")
        }
    }

    // MARK: - saveEpisode duration Tests

    func testSaveEpisodeDurationUpdatesDuration() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "duration-ep", duration: 3600, dataManager: dataManager)

            dataManager.saveEpisode(duration: 7200, episode: episode, updateSyncFlag: false)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.duration, 7200, "Duration should be updated")
        }
    }

    // MARK: - saveEpisode autoDownloadStatus Tests

    func testSaveEpisodeAutoDownloadStatusUpdatesStatus() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "auto-download-ep", dataManager: dataManager)

            dataManager.saveEpisode(autoDownloadStatus: .autoDownloaded, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.autoDownloadStatus, AutoDownloadStatus.autoDownloaded.rawValue, "Auto download status should be updated")
        }
    }

    // MARK: - saveEpisode downloadStatus with error Tests

    func testSaveEpisodeDownloadStatusWithErrorUpdatesFields() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "error-ep", dataManager: dataManager)

            dataManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: "Network error", downloadTaskId: nil, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.downloadFailed.rawValue, "Download status should be downloadFailed")
            XCTAssertEqual(found?.downloadErrorDetails, "Network error", "Error details should be saved")
        }
    }

    // MARK: - saveEpisode uploadStatus with taskId Tests

    func testSaveEpisodeUploadStatusWithTaskIdUpdatesFields() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "upload-task-ep", dataManager: dataManager)

            dataManager.saveEpisode(uploadStatus: .uploading, uploadTaskId: "task-456", episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.uploadStatus, UploadStatus.uploading.rawValue, "Upload status should be uploading")
        }
    }

    // MARK: - saveEpisode uploadStatus with error Tests

    func testSaveEpisodeUploadStatusWithErrorUpdatesFields() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "upload-error-ep", dataManager: dataManager)

            dataManager.saveEpisode(uploadStatus: .uploadFailed, uploadError: "Upload failed", uploadTaskId: nil, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.uploadStatus, UploadStatus.uploadFailed.rawValue, "Upload status should be uploadFailed")
        }
    }

    // MARK: - saveEpisode downloadStatus with lastDownloadAttemptDate Tests

    func testSaveEpisodeDownloadStatusWithAttemptDateUpdatesFields() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "attempt-date-ep", dataManager: dataManager)
            let attemptDate = Date()

            dataManager.saveEpisode(downloadStatus: .downloadFailed, lastDownloadAttemptDate: attemptDate, autoDownloadStatus: .userDeletedFile, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.downloadFailed.rawValue, "Download status should be updated")
            XCTAssertEqual(found?.autoDownloadStatus, AutoDownloadStatus.userDeletedFile.rawValue, "Auto download status should be updated")
            XCTAssertNotNil(found?.lastDownloadAttemptDate, "Last download attempt date should be set")
        }
    }

    // MARK: - saveEpisode playbackError Tests

    func testSaveEpisodePlaybackErrorUpdatesField() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "playback-error-ep", dataManager: dataManager)

            dataManager.saveEpisode(playbackError: "Codec not supported", episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.playbackErrorDetails, "Codec not supported", "Playback error should be saved")
        }
    }

    func testSaveEpisodePlaybackErrorClearsWhenNil() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "clear-error-ep", playbackError: "Some error", dataManager: dataManager)

            dataManager.saveEpisode(playbackError: nil, episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertNil(found?.playbackErrorDetails, "Playback error should be cleared")
        }
    }

    // MARK: - markImageUploaded Tests

    func testMarkImageUploadedClearsImageModifiedAndUrl() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "image-upload-ep", imageModified: 12345, imageUrl: "http://example.com/image.jpg", dataManager: dataManager)

            dataManager.markImageUploaded(episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.imageModified, 0, "Image modified should be reset to 0")
            XCTAssertNil(found?.imageUrl, "Image URL should be cleared")
        }
    }

    // MARK: - bulkUserFileDelete Tests

    func testBulkUserFileDeleteUpdatesStatus() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "bulk-delete-ep", episodeStatus: DownloadStatus.downloaded.rawValue, dataManager: dataManager)

            dataManager.bulkUserFileDelete(baseEpisodes: [episode])

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.episodeStatus, DownloadStatus.notDownloaded.rawValue, "Episode status should be notDownloaded")
            XCTAssertEqual(found?.autoDownloadStatus, AutoDownloadStatus.userDeletedFile.rawValue, "Auto download status should be userDeletedFile")
        }
    }

    // MARK: - saveEpisode contentType Tests

    func testSaveEpisodeContentTypeUpdatesContentType() throws {
        try runWithDataManager { dataManager in
            let episode = self.createTestUserEpisode(uuid: "content-type-ep", dataManager: dataManager)

            dataManager.saveEpisode(contentType: "audio/mpeg", episode: episode)

            let found = dataManager.findUserEpisode(uuid: episode.uuid)
            XCTAssertEqual(found?.contentType, "audio/mpeg", "Content type should be updated")
        }
    }

    // MARK: - allUserEpisodesUploaded Tests

    func testAllUserEpisodesUploadedReturnsOnlyUploaded() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(title: "Uploaded", uploadStatus: UploadStatus.uploaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Not Uploaded", uploadStatus: UploadStatus.notUploaded.rawValue, dataManager: dataManager)
            _ = self.createTestUserEpisode(title: "Uploading", uploadStatus: UploadStatus.uploading.rawValue, dataManager: dataManager)

            let episodes = dataManager.allUserEpisodesUploaded()

            XCTAssertEqual(episodes.count, 1, "Should only return uploaded episodes")
            XCTAssertEqual(episodes.first?.title, "Uploaded", "Should return the uploaded episode")
        }
    }

    // MARK: - findUserEpisodesWhereNotNull Tests

    func testFindUserEpisodesWhereNotNullReturnsMatchingEpisodes() throws {
        try runWithDataManager { dataManager in
            _ = self.createTestUserEpisode(uuid: "with-error", title: "With Error", playbackError: "Some error", dataManager: dataManager)
            _ = self.createTestUserEpisode(uuid: "without-error", title: "Without Error", dataManager: dataManager)

            let episodes = dataManager.findUserEpisodesWhereNotNull(propertyName: "playbackErrorDetails")

            XCTAssertTrue(episodes.contains { $0.uuid == "with-error" }, "Should include episode with playback error")
            XCTAssertFalse(episodes.contains { $0.uuid == "without-error" }, "Should not include episode without playback error")
        }
    }

    // MARK: - Helper Methods

    @discardableResult
    private func createTestUserEpisode(
        uuid: String = UUID().uuidString,
        title: String = "Test Episode",
        episodeStatus: Int32 = DownloadStatus.notDownloaded.rawValue,
        uploadStatus: Int32 = UploadStatus.notUploaded.rawValue,
        downloadTaskId: String? = nil,
        uploadTaskId: String? = nil,
        playingStatus: Int32 = PlayingStatus.notPlayed.rawValue,
        playedUpTo: Double = 0,
        playingStatusModified: Int64 = 0,
        titleModified: Int64 = 0,
        addedDate: Date = Date(),
        duration: Double = 3600,
        playbackError: String? = nil,
        imageModified: Int64 = 0,
        imageUrl: String? = nil,
        dataManager: DataManager
    ) -> UserEpisode {
        let episode = UserEpisode()
        episode.uuid = uuid
        episode.title = title
        episode.episodeStatus = episodeStatus
        episode.uploadStatus = uploadStatus
        episode.downloadTaskId = downloadTaskId
        episode.uploadTaskId = uploadTaskId
        episode.playingStatus = playingStatus
        episode.playedUpTo = playedUpTo
        episode.playingStatusModified = playingStatusModified
        episode.titleModified = titleModified
        episode.addedDate = addedDate
        episode.duration = duration
        episode.playbackErrorDetails = playbackError
        episode.imageModified = imageModified
        episode.imageUrl = imageUrl
        dataManager.save(episode: episode)
        return episode
    }
}
