import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for PodcastDataManager using the public API.
/// These tests run with both SQL and GRDB implementations.
final class PodcastDataManagerTests: DataManagerTestCase {

    // MARK: - findPodcast Tests

    func testFindPodcastByUuidReturnsPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "test-podcast-uuid", title: "Test Podcast", dataManager: dataManager)

            let found = dataManager.findPodcast(uuid: "test-podcast-uuid")

            XCTAssertNotNil(found, "\(impl): Should find podcast")
            XCTAssertEqual(found?.uuid, podcast.uuid, "\(impl): UUID should match")
            XCTAssertEqual(found?.title, podcast.title, "\(impl): Title should match")
        }
    }

    func testFindPodcastByUuidReturnsNilForNonExistent() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.findPodcast(uuid: "non-existent-uuid")

            XCTAssertNil(found, "\(impl): Should not find non-existent podcast")
        }
    }

    func testFindPodcastByUuidExcludesUnsubscribedByDefault() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "unsubscribed-podcast", subscribed: 0, dataManager: dataManager)

            let found = dataManager.findPodcast(uuid: "unsubscribed-podcast")

            XCTAssertNil(found, "\(impl): Should not find unsubscribed podcast by default")
        }
    }

    func testFindPodcastByUuidIncludesUnsubscribedWhenRequested() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "unsubscribed-podcast", subscribed: 0, dataManager: dataManager)

            let found = dataManager.findPodcast(uuid: "unsubscribed-podcast", includeUnsubscribed: true)

            XCTAssertNotNil(found, "\(impl): Should find unsubscribed podcast when includeUnsubscribed is true")
        }
    }

    // MARK: - allPodcasts Tests

    func testAllPodcastsReturnsAllSubscribedPodcasts() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Podcast 1", subscribed: 1, sortOrder: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 2", subscribed: 1, sortOrder: 2, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 3", subscribed: 1, sortOrder: 3, dataManager: dataManager)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)

            XCTAssertEqual(podcasts.count, 3, "\(impl): Should return 3 podcasts")
        }
    }

    func testAllPodcastsExcludesUnsubscribedByDefault() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed 1", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Subscribed 2", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, dataManager: dataManager)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should exclude unsubscribed podcast")
            XCTAssertTrue(podcasts.allSatisfy { $0.subscribed == 1 }, "\(impl): All podcasts should be subscribed")
        }
    }

    func testAllPodcastsIncludesUnsubscribedWhenRequested() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, dataManager: dataManager)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: true)

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should include unsubscribed podcast")
        }
    }

    func testAllPodcastsReturnsEmptyWhenNone() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcasts = dataManager.allPodcasts(includeUnsubscribed: true)

            XCTAssertTrue(podcasts.isEmpty, "\(impl): Should return empty array when no podcasts")
        }
    }

    // MARK: - randomPodcasts Tests

    func testRandomPodcastsReturnsSubset() throws {
        try runWithBothImplementations { dataManager, impl in
            for i in 0..<10 {
                _ = self.createTestPodcast(title: "Podcast \(i)", dataManager: dataManager)
            }

            let podcasts = dataManager.randomPodcasts()

            // randomPodcasts returns a limited number of random podcasts
            XCTAssertGreaterThan(podcasts.count, 0, "\(impl): Should return some podcasts")
            XCTAssertLessThanOrEqual(podcasts.count, 10, "\(impl): Should not return more than exist")
        }
    }

    func testRandomPodcastsReturnsAllWhenFew() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Podcast 1", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 2", dataManager: dataManager)

            let podcasts = dataManager.randomPodcasts()

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should return all podcasts when few exist")
        }
    }

    // MARK: - countOfPodcastsInFolder Tests

    func testCountOfPodcastsInFolderCountsPodcastsInFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "test-folder-uuid", name: "Test Folder", dataManager: dataManager)
            _ = self.createTestPodcast(title: "In Folder 1", folderUuid: folder.uuid, dataManager: dataManager)
            _ = self.createTestPodcast(title: "In Folder 2", folderUuid: folder.uuid, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Not In Folder", dataManager: dataManager)

            let count = dataManager.countOfPodcastsInFolder(folder: folder)

            XCTAssertEqual(count, 2, "\(impl): Should count only podcasts in folder")
        }
    }

    func testCountOfPodcastsInRootFolderCountsUnfolderedPodcasts() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "test-folder", name: "Test Folder", dataManager: dataManager)
            _ = self.createTestPodcast(title: "No Folder 1", dataManager: dataManager)
            _ = self.createTestPodcast(title: "No Folder 2", dataManager: dataManager)
            _ = self.createTestPodcast(title: "In Folder", folderUuid: folder.uuid, dataManager: dataManager)

            let count = dataManager.countOfPodcastsInRootFolder()

            XCTAssertEqual(count, 2, "\(impl): Should count only podcasts not in a folder")
        }
    }

    func testCountOfPodcastsInFolderExcludesUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "test-folder", name: "Test Folder", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, folderUuid: folder.uuid, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, folderUuid: folder.uuid, dataManager: dataManager)

            let count = dataManager.countOfPodcastsInFolder(folder: folder)

            XCTAssertEqual(count, 1, "\(impl): Should exclude unsubscribed podcasts")
        }
    }

    // MARK: - allUnsyncedPodcasts Tests

    func testAllUnsyncedPodcastsReturnsUnsyncedPodcasts() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Unsynced 1", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsynced 2", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Synced", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            let podcasts = dataManager.allUnsyncedPodcasts()

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should return only unsynced podcasts")
            XCTAssertTrue(podcasts.allSatisfy { $0.syncStatus == SyncStatus.notSynced.rawValue }, "\(impl): All should be unsynced")
        }
    }

    // MARK: - podcastUnfinishedCounts Tests

    func testPodcastUnfinishedCountsReturnsCorrectCounts() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast1 = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", dataManager: dataManager)
            let podcast2 = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", dataManager: dataManager)

            // Podcast 1: 2 unfinished episodes
            _ = self.createTestEpisode(podcast: podcast1, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast1, playingStatus: PlayingStatus.inProgress.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast1, playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)

            // Podcast 2: 1 unfinished episode
            _ = self.createTestEpisode(podcast: podcast2, playingStatus: PlayingStatus.notPlayed.rawValue, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast2, playingStatus: PlayingStatus.completed.rawValue, dataManager: dataManager)

            let counts = dataManager.podcastUnfinishedCounts()

            XCTAssertEqual(counts[podcast1.uuid], 2, "\(impl): Podcast 1 should have 2 unfinished")
            XCTAssertEqual(counts[podcast2.uuid], 1, "\(impl): Podcast 2 should have 1 unfinished")
        }
    }

    func testPodcastUnfinishedCountsExcludesArchivedEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", dataManager: dataManager)

            _ = self.createTestEpisode(podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, archived: false, dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast, playingStatus: PlayingStatus.notPlayed.rawValue, archived: true, dataManager: dataManager)

            let counts = dataManager.podcastUnfinishedCounts()

            XCTAssertEqual(counts[podcast.uuid], 1, "\(impl): Should exclude archived episode")
        }
    }

    // MARK: - delete Tests

    func testDeleteRemovesPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "to-delete", title: "To Delete", dataManager: dataManager)

            dataManager.delete(podcast: podcast)

            let found = dataManager.findPodcast(uuid: podcast.uuid, includeUnsubscribed: true)
            XCTAssertNil(found, "\(impl): Should delete podcast")
        }
    }

    // MARK: - markAllPodcastsSynced Tests

    func testMarkAllPodcastsSyncedMarksAllAsSynced() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Podcast 1", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 2", syncStatus: SyncStatus.notSynced.rawValue, dataManager: dataManager)

            dataManager.markAllPodcastsSynced()

            let unsynced = dataManager.allUnsyncedPodcasts()
            XCTAssertTrue(unsynced.isEmpty, "\(impl): All podcasts should be synced")
        }
    }

    // MARK: - markAllPodcastsUnsynced Tests

    func testMarkAllPodcastsUnsyncedMarksSubscribedAsUnsynced() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            dataManager.markAllPodcastsUnsynced()

            let unsynced = dataManager.allUnsyncedPodcasts()
            XCTAssertEqual(unsynced.count, 1, "\(impl): Only subscribed podcast should be unsynced")
            XCTAssertEqual(unsynced.first?.title, "Subscribed", "\(impl): Subscribed podcast should be unsynced")
        }
    }

    // MARK: - updateAllPodcastGrouping Tests

    func testUpdateAllPodcastGroupingUpdatesGrouping() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Podcast 1", episodeGrouping: PodcastGrouping.none.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 2", episodeGrouping: PodcastGrouping.none.rawValue, dataManager: dataManager)

            dataManager.updateAllPodcastGrouping(to: .season)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
            XCTAssertTrue(podcasts.allSatisfy { $0.episodeGrouping == PodcastGrouping.season.rawValue }, "\(impl): All podcasts should have season grouping")
        }
    }

    func testUpdateAllPodcastGroupingOnlyUpdatesSubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, episodeGrouping: PodcastGrouping.none.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, episodeGrouping: PodcastGrouping.none.rawValue, dataManager: dataManager)

            dataManager.updateAllPodcastGrouping(to: .season)

            let allPodcasts = dataManager.allPodcasts(includeUnsubscribed: true)
            let subscribed = allPodcasts.filter { $0.subscribed == 1 }
            let unsubscribed = allPodcasts.filter { $0.subscribed == 0 }

            XCTAssertTrue(subscribed.allSatisfy { $0.episodeGrouping == PodcastGrouping.season.rawValue }, "\(impl): Subscribed should have season grouping")
            XCTAssertTrue(unsubscribed.allSatisfy { $0.episodeGrouping == PodcastGrouping.none.rawValue }, "\(impl): Unsubscribed should be unchanged")
        }
    }

    // MARK: - updateAllShowArchived Tests

    func testUpdateAllShowArchivedUpdatesShowArchived() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Podcast 1", showArchived: false, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 2", showArchived: false, dataManager: dataManager)

            dataManager.updateAllShowArchived(to: true)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
            XCTAssertTrue(podcasts.allSatisfy { $0.showArchived == true }, "\(impl): All podcasts should show archived")
        }
    }

    func testUpdateAllShowArchivedOnlyUpdatesSubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, showArchived: false, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, showArchived: false, dataManager: dataManager)

            dataManager.updateAllShowArchived(to: true)

            let allPodcasts = dataManager.allPodcasts(includeUnsubscribed: true)
            let subscribed = allPodcasts.filter { $0.subscribed == 1 }
            let unsubscribed = allPodcasts.filter { $0.subscribed == 0 }

            XCTAssertTrue(subscribed.allSatisfy { $0.showArchived == true }, "\(impl): Subscribed should show archived")
            XCTAssertTrue(unsubscribed.allSatisfy { $0.showArchived == false }, "\(impl): Unsubscribed should be unchanged")
        }
    }

    // MARK: - allPodcastsInFolder Tests

    func testAllPodcastsInFolderReturnsPodcastsInFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "test-folder", name: "Test Folder", dataManager: dataManager)
            _ = self.createTestPodcast(title: "In Folder 1", folderUuid: folder.uuid, dataManager: dataManager)
            _ = self.createTestPodcast(title: "In Folder 2", folderUuid: folder.uuid, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Not In Folder", dataManager: dataManager)

            let podcasts = dataManager.allPodcastsInFolder(folder: folder)

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should return only podcasts in folder")
            XCTAssertTrue(podcasts.allSatisfy { $0.folderUuid == folder.uuid }, "\(impl): All should have folder UUID")
        }
    }

    // MARK: - delete(folderUuid:) Tests

    func testDeleteFolderRemovesPodcastsFromFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "folder-to-delete", name: "Delete Me", dataManager: dataManager)
            let podcast = self.createTestPodcast(title: "In Folder", folderUuid: folder.uuid, dataManager: dataManager)

            dataManager.delete(folderUuid: folder.uuid, markAsDeleted: false)

            // Podcast should no longer be in the folder
            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertNotNil(found, "\(impl): Podcast should still exist")
            XCTAssertNil(found?.folderUuid, "\(impl): Podcast should no longer have folder UUID")
        }
    }

    // MARK: - allPodcastsOrderedByAddedDate Tests

    func testAllPodcastsOrderedByAddedDateReturnsSortedByDate() throws {
        try runWithBothImplementations { dataManager, impl in
            let oldDate = Date(timeIntervalSinceNow: -86400 * 3)
            let midDate = Date(timeIntervalSinceNow: -86400)
            let newDate = Date()

            _ = self.createTestPodcast(title: "Middle", addedDate: midDate, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Oldest", addedDate: oldDate, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Newest", addedDate: newDate, dataManager: dataManager)

            let podcasts = dataManager.allPodcastsOrderedByAddedDate()

            XCTAssertEqual(podcasts.count, 3, "\(impl): Should return all podcasts")
            // Sorted by added date ascending (oldest first)
            XCTAssertEqual(podcasts.first?.title, "Oldest", "\(impl): Oldest should be first")
            XCTAssertEqual(podcasts.last?.title, "Newest", "\(impl): Newest should be last")
        }
    }

    func testAllPodcastsOrderedByAddedDateExcludesUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, dataManager: dataManager)

            let podcasts = dataManager.allPodcastsOrderedByAddedDate()

            XCTAssertEqual(podcasts.count, 1, "\(impl): Should exclude unsubscribed")
            XCTAssertEqual(podcasts.first?.title, "Subscribed", "\(impl): Should only include subscribed")
        }
    }

    // MARK: - allPodcastsOrderedByTitle Tests

    func testAllPodcastsOrderedByTitleReturnsSortedByTitle() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Zebra Podcast", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Alpha Podcast", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Middle Podcast", dataManager: dataManager)

            let podcasts = dataManager.allPodcastsOrderedByTitle()

            XCTAssertEqual(podcasts.count, 3, "\(impl): Should return all podcasts")
            XCTAssertEqual(podcasts.first?.title, "Alpha Podcast", "\(impl): Alpha should be first")
            XCTAssertEqual(podcasts.last?.title, "Zebra Podcast", "\(impl): Zebra should be last")
        }
    }

    func testAllPodcastsOrderedByTitleExcludesUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, dataManager: dataManager)

            let podcasts = dataManager.allPodcastsOrderedByTitle()

            XCTAssertEqual(podcasts.count, 1, "\(impl): Should exclude unsubscribed")
        }
    }

    // MARK: - allUnsubscribedPodcastUuids Tests

    func testAllUnsubscribedPodcastUuidsReturnsOnlyUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "subscribed-uuid", title: "Subscribed", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "unsubscribed-uuid-1", title: "Unsubscribed 1", subscribed: 0, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "unsubscribed-uuid-2", title: "Unsubscribed 2", subscribed: 0, dataManager: dataManager)

            let uuids = dataManager.allUnsubscribedPodcastUuids()

            XCTAssertEqual(uuids.count, 2, "\(impl): Should return 2 unsubscribed UUIDs")
            XCTAssertTrue(uuids.contains("unsubscribed-uuid-1"), "\(impl): Should contain first unsubscribed UUID")
            XCTAssertTrue(uuids.contains("unsubscribed-uuid-2"), "\(impl): Should contain second unsubscribed UUID")
            XCTAssertFalse(uuids.contains("subscribed-uuid"), "\(impl): Should not contain subscribed UUID")
        }
    }

    // MARK: - allUnsubscribedPodcasts Tests

    func testAllUnsubscribedPodcastsReturnsOnlyUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed 1", subscribed: 0, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed 2", subscribed: 0, dataManager: dataManager)

            let podcasts = dataManager.allUnsubscribedPodcasts()

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should return 2 unsubscribed podcasts")
            XCTAssertTrue(podcasts.allSatisfy { $0.subscribed == 0 }, "\(impl): All should be unsubscribed")
        }
    }

    // MARK: - allPaidPodcasts Tests

    func testAllPaidPodcastsReturnsPaidOnly() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Free Podcast", isPaid: false, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Paid Podcast 1", isPaid: true, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Paid Podcast 2", isPaid: true, dataManager: dataManager)

            let podcasts = dataManager.allPaidPodcasts()

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should return 2 paid podcasts")
            XCTAssertTrue(podcasts.allSatisfy { $0.isPaid }, "\(impl): All should be paid")
        }
    }

    // MARK: - allOverrideGlobalArchivePodcasts Tests

    func testAllOverrideGlobalArchivePodcastsReturnsOverridingPodcasts() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "No Override", overrideGlobalArchive: false, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Override 1", overrideGlobalArchive: true, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Override 2", overrideGlobalArchive: true, dataManager: dataManager)

            let podcasts = dataManager.allOverrideGlobalArchivePodcasts()

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should return 2 podcasts with override")
            XCTAssertTrue(podcasts.allSatisfy { $0.isAutoArchiveOverridden }, "\(impl): All should have override")
        }
    }

    func testAllOverrideGlobalArchivePodcastsExcludesUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed Override", subscribed: 1, overrideGlobalArchive: true, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed Override", subscribed: 0, overrideGlobalArchive: true, dataManager: dataManager)

            let podcasts = dataManager.allOverrideGlobalArchivePodcasts()

            XCTAssertEqual(podcasts.count, 1, "\(impl): Should exclude unsubscribed")
            XCTAssertEqual(podcasts.first?.title, "Subscribed Override", "\(impl): Should only include subscribed")
        }
    }

    // MARK: - searchPodcasts Tests

    func testSearchPodcastsMatchesTitle() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Tech Talk", author: "John", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Sports News", author: "Jane", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Tech Weekly", author: "Bob", dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "Tech")

            XCTAssertEqual(podcasts.count, 2, "\(impl): Should find 2 podcasts matching Tech")
        }
    }

    func testSearchPodcastsMatchesAuthor() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Podcast 1", author: "John Smith", dataManager: dataManager)
            _ = self.createTestPodcast(title: "Podcast 2", author: "Jane Doe", dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "John")

            XCTAssertEqual(podcasts.count, 1, "\(impl): Should find 1 podcast by author")
            XCTAssertEqual(podcasts.first?.author, "John Smith", "\(impl): Should match author")
        }
    }

    func testSearchPodcastsIsCaseInsensitive() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "TECH TALK", dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "tech")

            XCTAssertEqual(podcasts.count, 1, "\(impl): Should match case-insensitively")
        }
    }

    func testSearchPodcastsReturnsEmptyForNoMatch() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Sports News", dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "Tech")

            XCTAssertTrue(podcasts.isEmpty, "\(impl): Should return empty for no match")
        }
    }

    func testSearchPodcastsExcludesUnsubscribed() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Tech Subscribed", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Tech Unsubscribed", subscribed: 0, dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "Tech")

            XCTAssertEqual(podcasts.count, 1, "\(impl): Should exclude unsubscribed")
        }
    }

    func testSearchPodcastsHandlesEmptyTerm() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Any Podcast", dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "")

            XCTAssertTrue(podcasts.isEmpty, "\(impl): Should return empty for empty term")
        }
    }

    func testSearchPodcastsHandlesWhitespaceTerm() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Any Podcast", dataManager: dataManager)

            let podcasts = dataManager.searchPodcasts(term: "   ")

            XCTAssertTrue(podcasts.isEmpty, "\(impl): Should return empty for whitespace term")
        }
    }

    // MARK: - count Tests

    func testCountReturnsSubscribedPodcastCount() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(title: "Subscribed 1", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Subscribed 2", subscribed: 1, dataManager: dataManager)
            _ = self.createTestPodcast(title: "Unsubscribed", subscribed: 0, dataManager: dataManager)

            let count = dataManager.podcastCount()

            XCTAssertEqual(count, 2, "\(impl): Should count only subscribed podcasts")
        }
    }

    func testCountReturnsZeroWhenEmpty() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = dataManager.podcastCount()

            XCTAssertEqual(count, 0, "\(impl): Should return 0 when no podcasts")
        }
    }

    // MARK: - bulkSetFolderUuid Tests

    func testBulkSetFolderUuidSetsFolderOnPodcasts() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "target-folder", name: "Target Folder", dataManager: dataManager)
            let podcast1 = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", dataManager: dataManager)
            let podcast2 = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "podcast-3", title: "Podcast 3", dataManager: dataManager)

            dataManager.bulkSetFolderUuid(folderUuid: folder.uuid, podcastUuids: [podcast1.uuid, podcast2.uuid])

            let found1 = dataManager.findPodcast(uuid: podcast1.uuid)
            let found2 = dataManager.findPodcast(uuid: podcast2.uuid)
            let found3 = dataManager.findPodcast(uuid: "podcast-3")

            XCTAssertEqual(found1?.folderUuid, folder.uuid, "\(impl): Podcast 1 should be in folder")
            XCTAssertEqual(found2?.folderUuid, folder.uuid, "\(impl): Podcast 2 should be in folder")
            XCTAssertNil(found3?.folderUuid, "\(impl): Podcast 3 should not be in folder")
        }
    }

    func testBulkSetFolderUuidRemovesPreviousPodcastsFromFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "target-folder", name: "Target Folder", dataManager: dataManager)
            let oldPodcast = self.createTestPodcast(uuid: "old-podcast", title: "Old Podcast", folderUuid: folder.uuid, dataManager: dataManager)
            let newPodcast = self.createTestPodcast(uuid: "new-podcast", title: "New Podcast", dataManager: dataManager)

            dataManager.bulkSetFolderUuid(folderUuid: folder.uuid, podcastUuids: [newPodcast.uuid])

            let foundOld = dataManager.findPodcast(uuid: oldPodcast.uuid)
            let foundNew = dataManager.findPodcast(uuid: newPodcast.uuid)

            XCTAssertNil(foundOld?.folderUuid, "\(impl): Old podcast should be removed from folder")
            XCTAssertEqual(foundNew?.folderUuid, folder.uuid, "\(impl): New podcast should be in folder")
        }
    }

    // MARK: - saveSortOrders Tests

    func testSaveSortOrdersUpdatesPodcastSortOrders() throws {
        try runWithBothImplementations { dataManager, impl in
            var podcast1 = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", sortOrder: 0, dataManager: dataManager)
            var podcast2 = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", sortOrder: 1, dataManager: dataManager)

            podcast1.sortOrder = 10
            podcast2.sortOrder = 20
            dataManager.saveSortOrders(podcasts: [podcast1, podcast2])

            let found1 = dataManager.findPodcast(uuid: podcast1.uuid)
            let found2 = dataManager.findPodcast(uuid: podcast2.uuid)

            XCTAssertEqual(found1?.sortOrder, 10, "\(impl): Podcast 1 sort order should be updated")
            XCTAssertEqual(found2?.sortOrder, 20, "\(impl): Podcast 2 sort order should be updated")
        }
    }

    func testSaveSortOrdersMarksPodcastsUnsynced() throws {
        try runWithBothImplementations { dataManager, impl in
            var podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", sortOrder: 0, syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            podcast.sortOrder = 5
            dataManager.saveSortOrders(podcasts: [podcast])

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertEqual(found?.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): Podcast should be marked unsynced")
        }
    }

    // MARK: - savePushSetting Tests

    func testSavePushSettingUpdatesPodcastPushEnabled() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", pushEnabled: false, dataManager: dataManager)

            dataManager.savePushSetting(podcast: podcast, pushEnabled: true)

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertTrue(found?.pushEnabled ?? false, "\(impl): Push should be enabled")
        }
    }

    func testSavePushSettingByUuidUpdatesPodcastPushEnabled() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", pushEnabled: false, dataManager: dataManager)

            dataManager.savePushSetting(podcastUuid: podcast.uuid, pushEnabled: true)

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertTrue(found?.pushEnabled ?? false, "\(impl): Push should be enabled")
        }
    }

    // MARK: - setPushForAllPodcasts Tests

    func testSetPushForAllPodcastsEnablesPushForAll() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", pushEnabled: false, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", pushEnabled: false, dataManager: dataManager)

            dataManager.setPushForAllPodcasts(pushEnabled: true)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
            XCTAssertTrue(podcasts.allSatisfy { $0.pushEnabled }, "\(impl): All podcasts should have push enabled")
        }
    }

    func testSetPushForAllPodcastsDisablesPushForAll() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", pushEnabled: true, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", pushEnabled: true, dataManager: dataManager)

            dataManager.setPushForAllPodcasts(pushEnabled: false)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
            XCTAssertTrue(podcasts.allSatisfy { !$0.pushEnabled }, "\(impl): All podcasts should have push disabled")
        }
    }

    // MARK: - saveAutoAddToUpNext Tests

    func testSaveAutoAddToUpNextUpdatesPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", autoAddToUpNext: AutoAddToUpNextSetting.off.rawValue, dataManager: dataManager)

            dataManager.saveAutoAddToUpNext(podcastUuid: podcast.uuid, autoAddToUpNext: AutoAddToUpNextSetting.addFirst.rawValue)

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertEqual(found?.autoAddToUpNext, AutoAddToUpNextSetting.addFirst.rawValue, "\(impl): Auto add to up next should be updated")
        }
    }

    // MARK: - saveAutoAddToUpNextForAllPodcasts Tests

    func testSaveAutoAddToUpNextForAllPodcastsUpdatesAll() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", autoAddToUpNext: AutoAddToUpNextSetting.off.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", autoAddToUpNext: AutoAddToUpNextSetting.off.rawValue, dataManager: dataManager)

            dataManager.saveAutoAddToUpNextForAllPodcasts(autoAddToUpNext: AutoAddToUpNextSetting.addLast.rawValue)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
            XCTAssertTrue(podcasts.allSatisfy { $0.autoAddToUpNext == AutoAddToUpNextSetting.addLast.rawValue }, "\(impl): All podcasts should have auto add to up next set")
        }
    }

    // MARK: - setDownloadSettingForAllPodcasts Tests

    func testSetDownloadSettingForAllPodcastsUpdatesAll() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", autoDownloadSetting: AutoDownloadSetting.off.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", autoDownloadSetting: AutoDownloadSetting.off.rawValue, dataManager: dataManager)

            dataManager.setDownloadSettingForAllPodcasts(setting: .latest)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
            XCTAssertTrue(podcasts.allSatisfy { $0.autoDownloadSetting == AutoDownloadSetting.latest.rawValue }, "\(impl): All podcasts should have download setting updated")
        }
    }

    // MARK: - savePodcastDownloadSetting Tests

    func testSavePodcastDownloadSettingUpdatesPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", autoDownloadSetting: AutoDownloadSetting.off.rawValue, dataManager: dataManager)

            dataManager.savePodcastDownloadSetting(.latest, podcastUuid: podcast.uuid)

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertEqual(found?.autoDownloadSetting, AutoDownloadSetting.latest.rawValue, "\(impl): Download setting should be updated")
        }
    }

    // MARK: - saveAutoArchiveLimit Tests

    func testSaveAutoArchiveLimitUpdatesPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", autoArchiveEpisodeLimit: 0, dataManager: dataManager)

            dataManager.saveAutoArchiveLimit(podcast: podcast, limit: 10)

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertEqual(found?.autoArchiveEpisodeLimit, 10, "\(impl): Auto archive limit should be updated")
        }
    }

    // MARK: - setPodcastImageVersion Tests

    func testSetPodcastImageVersionDoesNotCrash() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", dataManager: dataManager)

            // setPodcastImageVersion updates an internal field, verify it doesn't crash
            dataManager.setPodcastImageVersion(podcastUuid: podcast.uuid, version: 5)

            // Verify podcast still exists after update
            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertNotNil(found, "\(impl): Podcast should still exist after image version update")
        }
    }

    // MARK: - updatePodcastFolder Tests

    func testUpdatePodcastFolderUpdatesFolderAndSortOrder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "test-folder", name: "Test Folder", dataManager: dataManager)
            let podcast = self.createTestPodcast(uuid: "podcast-1", title: "Podcast", sortOrder: 0, dataManager: dataManager)

            dataManager.updatePodcastFolder(podcastUuid: podcast.uuid, to: folder.uuid, sortOrder: 5)

            let found = dataManager.findPodcast(uuid: podcast.uuid)
            XCTAssertEqual(found?.folderUuid, folder.uuid, "\(impl): Folder UUID should be updated")
            XCTAssertEqual(found?.sortOrder, 5, "\(impl): Sort order should be updated")
        }
    }

    // MARK: - markAllPodcastsUnsyncedWhereLastSyncAtNot Tests

    func testMarkAllPodcastsUnsyncedWhereLastSyncAtNotDoesNotCrash() throws {
        try runWithBothImplementations { dataManager, impl in
            // Create some synced podcasts
            _ = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)
            _ = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", syncStatus: SyncStatus.synced.rawValue, dataManager: dataManager)

            // Call the method with a sync time - it should not crash
            dataManager.markAllPodcastsUnsyncedWhereLastSyncAtNot("1000")

            // Verify podcasts still exist
            let found1 = dataManager.findPodcast(uuid: "podcast-1")
            let found2 = dataManager.findPodcast(uuid: "podcast-2")

            XCTAssertNotNil(found1, "\(impl): Podcast 1 should still exist")
            XCTAssertNotNil(found2, "\(impl): Podcast 2 should still exist")
        }
    }

    // MARK: - allPodcastsOrderedByNewestEpisodes Tests

    func testAllPodcastsOrderedByNewestEpisodesReturnsSortedByLatestRelease() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast1 = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", dataManager: dataManager)
            let podcast2 = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", dataManager: dataManager)
            let podcast3 = self.createTestPodcast(uuid: "podcast-3", title: "Podcast 3", dataManager: dataManager)

            // Add episodes with different release dates
            _ = self.createTestEpisode(podcast: podcast1, publishedDate: Date(timeIntervalSinceNow: -86400 * 3), dataManager: dataManager) // 3 days ago
            _ = self.createTestEpisode(podcast: podcast2, publishedDate: Date(), dataManager: dataManager) // Today
            _ = self.createTestEpisode(podcast: podcast3, publishedDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager) // 1 day ago

            let podcasts = dataManager.allPodcastsOrderedByNewestEpisodes()

            XCTAssertGreaterThanOrEqual(podcasts.count, 3, "\(impl): Should return all podcasts")
            // The podcast with the newest episode should be first
            XCTAssertEqual(podcasts.first?.uuid, podcast2.uuid, "\(impl): Podcast with newest episode should be first")
        }
    }

    // MARK: - allPodcastsOrderedByLastPlayedEpisodes Tests

    func testAllPodcastsOrderedByLastPlayedEpisodesReturnsSortedByLastPlayed() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast1 = self.createTestPodcast(uuid: "podcast-1", title: "Podcast 1", dataManager: dataManager)
            let podcast2 = self.createTestPodcast(uuid: "podcast-2", title: "Podcast 2", dataManager: dataManager)
            let podcast3 = self.createTestPodcast(uuid: "podcast-3", title: "Podcast 3", dataManager: dataManager)

            // Add episodes with different last playback interaction dates
            _ = self.createTestEpisode(podcast: podcast1, lastPlaybackInteractionDate: Date(timeIntervalSinceNow: -86400 * 3), dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast2, lastPlaybackInteractionDate: Date(), dataManager: dataManager)
            _ = self.createTestEpisode(podcast: podcast3, lastPlaybackInteractionDate: Date(timeIntervalSinceNow: -86400), dataManager: dataManager)

            let podcasts = dataManager.allPodcastsOrderedByLastPlayedEpisodes()

            XCTAssertGreaterThanOrEqual(podcasts.count, 3, "\(impl): Should return all podcasts")
            // The podcast with the most recently played episode should be first
            XCTAssertEqual(podcasts.first?.uuid, podcast2.uuid, "\(impl): Podcast with most recently played episode should be first")
        }
    }

    // MARK: - Helper to create episode for podcast tests

    @discardableResult
    func createTestEpisode(
        uuid: String = UUID().uuidString,
        podcast: Podcast,
        publishedDate: Date = Date(),
        lastPlaybackInteractionDate: Date? = nil,
        dataManager: DataManager
    ) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.title = "Test Episode"
        episode.publishedDate = publishedDate
        episode.addedDate = Date()
        episode.lastPlaybackInteractionDate = lastPlaybackInteractionDate
        dataManager.save(episode: episode)
        return episode
    }

    // MARK: - Helper to create podcast with additional properties

    func createTestPodcast(
        uuid: String = UUID().uuidString,
        title: String = "Test Podcast",
        author: String? = nil,
        subscribed: Int32 = 1,
        sortOrder: Int32 = 0,
        folderUuid: String? = nil,
        syncStatus: Int32 = SyncStatus.notSynced.rawValue,
        showArchived: Bool = false,
        episodeGrouping: Int32 = 0,
        isPaid: Bool = false,
        overrideGlobalArchive: Bool = false,
        addedDate: Date = Date(),
        pushEnabled: Bool = false,
        autoAddToUpNext: Int32 = AutoAddToUpNextSetting.off.rawValue,
        autoDownloadSetting: Int32 = AutoDownloadSetting.off.rawValue,
        autoArchiveEpisodeLimit: Int32 = 0,
        dataManager: DataManager
    ) -> Podcast {
        let podcast = Podcast()
        podcast.uuid = uuid
        podcast.title = title
        podcast.author = author
        podcast.subscribed = subscribed
        podcast.sortOrder = sortOrder
        podcast.folderUuid = folderUuid
        podcast.syncStatus = syncStatus
        podcast.showArchived = showArchived
        podcast.episodeGrouping = episodeGrouping
        podcast.isPaid = isPaid
        podcast.overrideGlobalArchive = overrideGlobalArchive
        podcast.addedDate = addedDate
        podcast.pushEnabled = pushEnabled
        podcast.autoAddToUpNext = autoAddToUpNext
        podcast.autoDownloadSetting = autoDownloadSetting
        podcast.autoArchiveEpisodeLimit = autoArchiveEpisodeLimit
        dataManager.save(podcast: podcast)
        return podcast
    }
}
