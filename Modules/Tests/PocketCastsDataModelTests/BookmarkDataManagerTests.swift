@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest

/// Coverage for BookmarkDataManager.
final class BookmarkDataManagerTests: DataManagerTestCase {

    // MARK: - Adding

    func testAddBookmarkSucceeds() throws {
        try runWithDataManager { dataManager in
            let uuid = try XCTUnwrap(
                dataManager.bookmarks.add(
                    episodeUuid: "episode-uuid",
                    podcastUuid: "podcast-uuid",
                    title: "Title",
                    time: 1
                ),
                "should return bookmark uuid"
            )

            XCTAssertNotNil(dataManager.bookmarks.bookmark(for: uuid), "bookmark should be persisted")
        }
    }

    func testAddingEpisodeOnlyBookmarkSucceeds() throws {
        try runWithDataManager { dataManager in
            let uuid = try XCTUnwrap(
                dataManager.bookmarks.add(
                    episodeUuid: "episode-uuid",
                    podcastUuid: nil,
                    title: "Title",
                    time: 1
                ),
                "should return bookmark uuid"
            )

            let bookmark = dataManager.bookmarks.bookmark(for: uuid)
            XCTAssertEqual(bookmark?.podcastUuid, nil, "podcastUuid should be nil")
        }
    }

    func testAddingDuplicateBookmarkDoesNotCrash() throws {
        try runWithDataManager { dataManager in
            _ = addBookmark(dataManager: dataManager)
            _ = addBookmark(dataManager: dataManager)

            XCTAssertEqual(dataManager.bookmarks.allBookmarks().count, 2, "should allow duplicates by time")
        }
    }

    func testAddingBookmarksForMultipleEpisodesCountsCorrectly() throws {
        try runWithDataManager { dataManager in
            let episodes = ["ep-1", "ep-2", "ep-3"]
            episodes.forEach { episode in
                addBookmark(episodeUuid: episode, dataManager: dataManager)
            }

            XCTAssertEqual(
                dataManager.bookmarks.bookmarks(forEpisode: "ep-1").count,
                1,
                "should only count bookmarks for episode"
            )
            XCTAssertEqual(dataManager.bookmarks.allBookmarks().count, 3, "should have 3 total bookmarks")
        }
    }

    // MARK: - Retrieving

    func testGettingAllBookmarksForPodcast() throws {
        try runWithDataManager { dataManager in
            let podcast = "podcast-uuid"

            ["episode-1", "episode-2"].forEach {
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 1, dataManager: dataManager)
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 3, dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forPodcast: podcast)
            XCTAssertEqual(bookmarks.count, 4, "should return all bookmarks for podcast")
        }
    }

    func testGettingAllBookmarksForPodcastAndEpisode() throws {
        try runWithDataManager { dataManager in
            let podcast = "podcast-uuid"

            ["episode-1", "episode-2"].forEach {
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 1, dataManager: dataManager)
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 3, dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forPodcast: podcast, episodeUuid: "episode-2")
            XCTAssertEqual(bookmarks.count, 2, "should filter to a single episode")
        }
    }

    // MARK: - Counts

    func testBookmarkReturnsCorrectly() throws {
        try runWithDataManager { dataManager in
            let count = 10

            for i in 0..<count {
                addBookmark(episodeUuid: "episode", time: Double(i), dataManager: dataManager)
            }

            XCTAssertEqual(dataManager.bookmarks.bookmarkCount(forEpisode: "episode"), count, "count should match added bookmarks")
        }
    }

    func testDeletedBookmarksAreExcludedFromCount() async throws {
        try await runWithDataManager { dataManager in
            let count = 10

            let deletedBookmark = addBookmark(episodeUuid: "episode", time: 1234, dataManager: dataManager)

            for i in 0..<count {
                addBookmark(episodeUuid: "episode", time: Double(i), dataManager: dataManager)
            }

            _ = await dataManager.bookmarks.remove(bookmarks: [deletedBookmark])

            XCTAssertEqual(dataManager.bookmarks.bookmarkCount(forEpisode: "episode"), count, "deleted bookmarks should be excluded")
        }
    }

    func testBookmarkCountCanIncludeDeletedItems() async throws {
        try await runWithDataManager { dataManager in
            let count = 10

            let deletedBookmark = addBookmark(episodeUuid: "episode", time: 1234, dataManager: dataManager)

            for i in 0..<count {
                addBookmark(episodeUuid: "episode", time: Double(i), dataManager: dataManager)
            }

            _ = await dataManager.bookmarks.remove(bookmarks: [deletedBookmark])

            XCTAssertEqual(
                dataManager.bookmarks.bookmarkCount(forEpisode: "episode", includeDeleted: true),
                count + 1,
                "includeDeleted should count removed bookmark"
            )
        }
    }

    // MARK: - Data Validation

    func testBookmarkReturnsCorrectValues() throws {
        try runWithDataManager { dataManager in
            let created = Date(timeIntervalSince1970: 0)
            let episode = "episode-uuid"
            let podcast = "podcast-uuid"
            let time: TimeInterval = 12345
            let title = "Hello World"

            let bookmark = addBookmark(
                episodeUuid: episode,
                podcastUuid: podcast,
                title: title,
                time: time,
                created: created,
                dataManager: dataManager
            )

            XCTAssertEqual(bookmark.created, created, "created should match")
            XCTAssertEqual(bookmark.episodeUuid, episode, "episode uuid should match")
            XCTAssertEqual(bookmark.titleModified, created, "title modified should match created")
            XCTAssertEqual(bookmark.podcastUuid, podcast, "podcast should match")
            XCTAssertEqual(bookmark.time, time, "time should match")
            XCTAssertEqual(bookmark.title, title, "title should match")
        }
    }

    // MARK: - Updating

    func testUpdatingTitleSucceeds() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)

            let success = await dataManager.bookmarks.update(bookmark: bookmark, title: "title2")
            XCTAssertTrue(success, "update should succeed")
        }
    }

    func testUpdatingTheTitleSaves() async throws {
        try await runWithDataManager { dataManager in
            let title1 = "First Title"
            let title2 = "Second Title"
            let modified = Date(timeIntervalSince1970: 10)

            let bookmark = addBookmark(title: title1, dataManager: dataManager)

            await dataManager.bookmarks.update(bookmark: bookmark, title: title2, modified: modified)

            let updatedBookmark = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertEqual(updatedBookmark?.title, title2, "title should update")
            XCTAssertEqual(updatedBookmark?.titleModified, modified, "modified should update")
        }
    }

    func testUpdatingTitleEffectsOnlyOneBookmark() async throws {
        try await runWithDataManager { dataManager in
            let titles = ["a_title", "b_title", "c_title", "d_title"].sorted()

            let bookmarks = titles.map { addBookmark(episodeUuid: $0, title: $0, dataManager: dataManager) }
            let bookmarkToChange = 2
            let title2 = "c_title_2"

            await dataManager.bookmarks.update(bookmark: bookmarks[bookmarkToChange], title: title2)

            let updatedTitles = dataManager.bookmarks.allBookmarks().map { $0.title }.sorted()
            XCTAssertNotEqual(titles, updatedTitles, "titles should differ after update")
            XCTAssertEqual(updatedTitles[bookmarkToChange], title2, "only targeted bookmark should change")
        }
    }

    // MARK: - Deletion

    func testRemovingBookmarksSucceeds() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)
            let success = await dataManager.bookmarks.remove(bookmarks: [bookmark])
            XCTAssertTrue(success, "removal should succeed")
        }
    }

    func testRemovedBookmarksArentReturned() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)
            _ = await dataManager.bookmarks.remove(bookmarks: [bookmark])

            XCTAssertNil(dataManager.bookmarks.bookmark(for: bookmark.uuid), "removed bookmark should not be returned")
        }
    }

    func testAllBookmarksAlsoReturnsDeletedItems() async throws {
        try await runWithDataManager { dataManager in
            let bookmarkNotDeleted = addBookmark(time: 1, dataManager: dataManager)
            let bookmark = addBookmark(time: 2, dataManager: dataManager)

            _ = await dataManager.bookmarks.remove(bookmarks: [bookmark])
            let allBookmarks = dataManager.bookmarks.allBookmarks(includeDeleted: true, sorted: .timestamp)

            XCTAssertEqual([bookmarkNotDeleted.uuid, bookmark.uuid], allBookmarks.map(\.uuid), "should return deleted and active")
        }
    }

    func testBookmarkIsPermanentlyRemoved() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)
            let success = await dataManager.bookmarks.permanentlyDelete(bookmarks: [bookmark])
            XCTAssertTrue(success, "permanent delete should succeed")

            XCTAssertTrue(dataManager.bookmarks.allBookmarks(includeDeleted: true).isEmpty, "table should be empty")
        }
    }

    // MARK: - Sorting

    func testNewestToOldestSorting() throws {
        try runWithDataManager { dataManager in
            let episode = "episode"

            let ordered = [(0, 0), (1, 10), (2, 20), (3, 30)].map { values in
                addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1), dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forEpisode: episode, sorted: .newestToOldest)

            XCTAssertEqual(ordered.reversed().map(\.uuid), bookmarks.map(\.uuid), "should be sorted newest to oldest")
        }
    }

    func testOldestToNewestSorting() throws {
        try runWithDataManager { dataManager in
            let episode = "episode"

            let ordered = [(0, 0), (1, 10), (2, 20), (3, 30)].map { values in
                addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1), dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forEpisode: episode, sorted: .oldestToNewest)

            XCTAssertEqual(ordered.map(\.uuid), bookmarks.map(\.uuid), "should be sorted oldest to newest")
        }
    }

    func testTimestampSorting() throws {
        try runWithDataManager { dataManager in
            let episode = "episode"

            let ordered = [(0, 24), (3600, 1), (7200, 123), (86400, 321)].map { values in
                addBookmark(
                    episodeUuid: episode,
                    time: values.0,
                    created: .init(timeIntervalSince1970: values.1),
                    dataManager: dataManager
                )
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forEpisode: episode, sorted: .timestamp)

            XCTAssertEqual(ordered.map(\.uuid), bookmarks.map(\.uuid), "should be sorted by timestamp")
        }
    }

    // MARK: - Syncing

    func testBookmarksToSyncReturnsOnlyItemsThatNeedSyncing() throws {
        try runWithDataManager { dataManager in
            let count = 10

            for i in 0..<count {
                addBookmark(time: TimeInterval(i), dataManager: dataManager)
            }

            addBookmark(time: TimeInterval(999), syncStatus: .synced, dataManager: dataManager)

            let unsyncedBookmarks = dataManager.bookmarks.bookmarksToSync()
            XCTAssertEqual(unsyncedBookmarks.count, count, "only unsynced should be returned")
        }
    }

    func testUpdatingTitleMarksAsNotSynced() async throws {
        try await runWithDataManager { dataManager in
            addBookmark(time: TimeInterval(123), syncStatus: .synced, dataManager: dataManager)

            let bookmark = addBookmark(time: TimeInterval(999), syncStatus: .synced, dataManager: dataManager)
            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title")

            XCTAssertEqual(dataManager.bookmarks.bookmarksToSync().count, 1, "update should mark bookmark as needing sync")
        }
    }

    func testUpdatingTitleUpdatesTheModifiedDate() async throws {
        try await runWithDataManager { dataManager in
            let created = Date(timeIntervalSince1970: 1234)
            let bookmark = addBookmark(time: TimeInterval(999), created: created, syncStatus: .synced, dataManager: dataManager)
            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title")

            let updatedBookmark = dataManager.bookmarks.bookmark(for: bookmark.uuid)

            XCTAssertNotEqual(updatedBookmark?.titleModified, created, "modified date should update")
        }
    }

    func testUpdatingWithSyncStatusSetsCorrectly() async throws {
        try await runWithDataManager { dataManager in
            addBookmark(time: TimeInterval(123), syncStatus: .synced, dataManager: dataManager)
            let bookmark = addBookmark(time: TimeInterval(999), dataManager: dataManager)
            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title", syncStatus: .synced)

            XCTAssertEqual(dataManager.bookmarks.bookmarksToSync().count, 0, "syncStatus should be updated")
        }
    }

    func testDeletingUpdatesSyncStatus() async throws {
        try await runWithDataManager { dataManager in
            addBookmark(time: TimeInterval(123), syncStatus: .synced, dataManager: dataManager)
            let bookmark = addBookmark(time: TimeInterval(999), syncStatus: .synced, dataManager: dataManager)
            _ = await dataManager.bookmarks.remove(bookmarks: [bookmark])

            XCTAssertEqual(dataManager.bookmarks.bookmarksToSync().count, 1, "delete should mark for sync")
        }
    }

    // MARK: - Passage

    func testAddingBookmarkWithPassageRoundTrips() throws {
        try runWithDataManager { dataManager in
            let passageModified = Date(timeIntervalSince1970: 100)
            let referenceTimeModified = Date(timeIntervalSince1970: 200)

            let uuid = try XCTUnwrap(dataManager.bookmarks.add(
                episodeUuid: "episode-uuid",
                podcastUuid: "podcast-uuid",
                title: "Title",
                time: 1,
                passage: "A memorable passage",
                passageLocation: 42,
                passageModified: passageModified,
                referenceTime: 118,
                referenceTimeModified: referenceTimeModified
            ), "should return bookmark uuid")

            let bookmark = try XCTUnwrap(dataManager.bookmarks.bookmark(for: uuid), "bookmark should be persisted")
            XCTAssertEqual(bookmark.passage, "A memorable passage", "passage should round trip")
            XCTAssertEqual(bookmark.passageLocation, 42, "passageLocation should round trip")
            XCTAssertEqual(bookmark.passageModified, passageModified, "passageModified should round trip")
            XCTAssertEqual(bookmark.referenceTime, 118, "referenceTime should round trip")
            XCTAssertEqual(bookmark.referenceTimeModified, referenceTimeModified, "referenceTimeModified should round trip")
        }
    }

    func testAddingBookmarkWithoutPassageIsNil() throws {
        try runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)

            XCTAssertNil(bookmark.passage, "passage should be nil")
            XCTAssertNil(bookmark.passageLocation, "passageLocation should be nil")
            XCTAssertNil(bookmark.passageModified, "passageModified should be nil")
            XCTAssertNil(bookmark.referenceTime, "referenceTime should be nil")
            XCTAssertNil(bookmark.referenceTimeModified, "referenceTimeModified should be nil")
        }
    }

    func testUpdatingPassageSaves() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)
            let modified = Date(timeIntervalSince1970: 300)

            await dataManager.bookmarks.update(bookmark: bookmark, passage: "New passage", passageLocation: 7, passageModified: modified)

            let updated = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertEqual(updated?.passage, "New passage", "passage should update")
            XCTAssertEqual(updated?.passageLocation, 7, "passageLocation should update")
            XCTAssertEqual(updated?.passageModified, modified, "passageModified should update")
        }
    }

    func testUpdatingReferenceTimeSaves() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)
            let modified = Date(timeIntervalSince1970: 300)

            await dataManager.bookmarks.update(bookmark: bookmark, referenceTime: 45, referenceTimeModified: modified)

            let updated = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertEqual(updated?.referenceTime, 45, "referenceTime should update")
            XCTAssertEqual(updated?.referenceTimeModified, modified, "referenceTimeModified should update")
        }
    }

    func testUpdatingTitleLeavesPassageUntouched() async throws {
        try await runWithDataManager { dataManager in
            let uuid = try XCTUnwrap(dataManager.bookmarks.add(
                episodeUuid: "episode-uuid",
                podcastUuid: "podcast-uuid",
                title: "Title",
                time: 1,
                passage: "A passage",
                passageLocation: 3,
                passageModified: Date(timeIntervalSince1970: 100)
            ))
            let bookmark = try XCTUnwrap(dataManager.bookmarks.bookmark(for: uuid))

            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title")

            let updated = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertEqual(updated?.title, "New Title", "title should update")
            XCTAssertEqual(updated?.passage, "A passage", "passage should be untouched")
            XCTAssertEqual(updated?.passageLocation, 3, "passageLocation should be untouched")
        }
    }

    func testUpdatingPassageWithoutModifiedDateIsIgnored() async throws {
        try await runWithDataManager { dataManager in
            let bookmark = addBookmark(dataManager: dataManager)

            await dataManager.bookmarks.update(bookmark: bookmark, passage: "New passage", passageLocation: 7)

            let updated = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertNil(updated?.passage, "passage without a modified date should be ignored")
            XCTAssertNil(updated?.passageLocation, "passageLocation without a modified date should be ignored")
        }
    }

    func testClearingPassageSaves() async throws {
        try await runWithDataManager { dataManager in
            let uuid = try XCTUnwrap(dataManager.bookmarks.add(
                episodeUuid: "episode-uuid",
                podcastUuid: "podcast-uuid",
                title: "Title",
                time: 1,
                passage: "A passage",
                passageLocation: 3,
                passageModified: Date(timeIntervalSince1970: 100)
            ))
            let bookmark = try XCTUnwrap(dataManager.bookmarks.bookmark(for: uuid))
            let modified = Date(timeIntervalSince1970: 300)

            await dataManager.bookmarks.update(bookmark: bookmark, passageModified: modified)

            let updated = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertNil(updated?.passage, "passage should clear")
            XCTAssertNil(updated?.passageLocation, "passageLocation should clear")
            XCTAssertEqual(updated?.passageModified, modified, "passageModified should update")
        }
    }

    // MARK: - Helpers

    @discardableResult
    private func addBookmark(
        episodeUuid: String = "episode-1",
        podcastUuid: String = "podcast-uuid",
        title: String = "Title",
        time: TimeInterval = 1,
        created: Date = .now,
        syncStatus: SyncStatus = .notSynced,
        dataManager: DataManager
    ) -> Bookmark {
        let uuid = dataManager.bookmarks.add(
            episodeUuid: episodeUuid,
            podcastUuid: podcastUuid,
            title: title,
            time: time,
            dateCreated: created,
            syncStatus: syncStatus
        )

        return try! XCTUnwrap(
            uuid.flatMap { dataManager.bookmarks.bookmark(for: $0) },
            "Bookmark should be saved"
        )
    }
}
