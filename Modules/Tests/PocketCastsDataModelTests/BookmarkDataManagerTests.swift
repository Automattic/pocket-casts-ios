@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest

/// Coverage for BookmarkDataManager that now runs against both SQL and GRDB
/// implementations via the FeatureFlag.grdbQueryInterface toggle.
final class BookmarkDataManagerTests: DataManagerTestCase {

    // MARK: - Adding

    func testAddBookmarkSucceeds() throws {
        try runWithBothImplementations { dataManager, impl in
            let uuid = try XCTUnwrap(
                dataManager.bookmarks.add(
                    episodeUuid: "episode-uuid",
                    podcastUuid: "podcast-uuid",
                    title: "Title",
                    time: 1
                ),
                "\(impl): should return bookmark uuid"
            )

            XCTAssertNotNil(dataManager.bookmarks.bookmark(for: uuid), "\(impl): bookmark should be persisted")
        }
    }

    func testAddingEpisodeOnlyBookmarkSucceeds() throws {
        try runWithBothImplementations { dataManager, impl in
            let uuid = try XCTUnwrap(
                dataManager.bookmarks.add(
                    episodeUuid: "episode-uuid",
                    podcastUuid: nil,
                    title: "Title",
                    time: 1
                ),
                "\(impl): should return bookmark uuid"
            )

            let bookmark = dataManager.bookmarks.bookmark(for: uuid)
            XCTAssertEqual(bookmark?.podcastUuid, nil, "\(impl): podcastUuid should be nil")
        }
    }

    func testAddingDuplicateBookmarkDoesNotCrash() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = addBookmark(dataManager: dataManager)
            _ = addBookmark(dataManager: dataManager)

            XCTAssertEqual(dataManager.bookmarks.allBookmarks().count, 2, "\(impl): should allow duplicates by time")
        }
    }

    func testAddingBookmarksForMultipleEpisodesCountsCorrectly() throws {
        try runWithBothImplementations { dataManager, impl in
            let episodes = ["ep-1", "ep-2", "ep-3"]
            episodes.forEach { episode in
                addBookmark(episodeUuid: episode, dataManager: dataManager)
            }

            XCTAssertEqual(
                dataManager.bookmarks.bookmarks(forEpisode: "ep-1").count,
                1,
                "\(impl): should only count bookmarks for episode"
            )
            XCTAssertEqual(dataManager.bookmarks.allBookmarks().count, 3, "\(impl): should have 3 total bookmarks")
        }
    }

    // MARK: - Retrieving

    func testGettingAllBookmarksForPodcast() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = "podcast-uuid"

            ["episode-1", "episode-2"].forEach {
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 1, dataManager: dataManager)
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 3, dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forPodcast: podcast)
            XCTAssertEqual(bookmarks.count, 4, "\(impl): should return all bookmarks for podcast")
        }
    }

    func testGettingAllBookmarksForPodcastAndEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = "podcast-uuid"

            ["episode-1", "episode-2"].forEach {
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 1, dataManager: dataManager)
                addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 3, dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forPodcast: podcast, episodeUuid: "episode-2")
            XCTAssertEqual(bookmarks.count, 2, "\(impl): should filter to a single episode")
        }
    }

    // MARK: - Counts

    func testBookmarkReturnsCorrectly() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = 10

            for i in 0..<count {
                addBookmark(episodeUuid: "episode", time: Double(i), dataManager: dataManager)
            }

            XCTAssertEqual(dataManager.bookmarks.bookmarkCount(forEpisode: "episode"), count, "\(impl): count should match added bookmarks")
        }
    }

    func testDeletedBookmarksAreExcludedFromCount() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let count = 10

            let deletedBookmark = addBookmark(episodeUuid: "episode", time: 1234, dataManager: dataManager)

            for i in 0..<count {
                addBookmark(episodeUuid: "episode", time: Double(i), dataManager: dataManager)
            }

            _ = await dataManager.bookmarks.remove(bookmarks: [deletedBookmark])

            XCTAssertEqual(dataManager.bookmarks.bookmarkCount(forEpisode: "episode"), count, "\(impl): deleted bookmarks should be excluded")
        }
    }

    func testBookmarkCountCanIncludeDeletedItems() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let count = 10

            let deletedBookmark = addBookmark(episodeUuid: "episode", time: 1234, dataManager: dataManager)

            for i in 0..<count {
                addBookmark(episodeUuid: "episode", time: Double(i), dataManager: dataManager)
            }

            _ = await dataManager.bookmarks.remove(bookmarks: [deletedBookmark])

            XCTAssertEqual(
                dataManager.bookmarks.bookmarkCount(forEpisode: "episode", includeDeleted: true),
                count + 1,
                "\(impl): includeDeleted should count removed bookmark"
            )
        }
    }

    // MARK: - Data Validation

    func testBookmarkReturnsCorrectValues() throws {
        try runWithBothImplementations { dataManager, impl in
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

            XCTAssertEqual(bookmark.created, created, "\(impl): created should match")
            XCTAssertEqual(bookmark.episodeUuid, episode, "\(impl): episode uuid should match")
            XCTAssertEqual(bookmark.titleModified, created, "\(impl): title modified should match created")
            XCTAssertEqual(bookmark.podcastUuid, podcast, "\(impl): podcast should match")
            XCTAssertEqual(bookmark.time, time, "\(impl): time should match")
            XCTAssertEqual(bookmark.title, title, "\(impl): title should match")
        }
    }

    // MARK: - Updating

    func testUpdatingTitleSucceeds() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let bookmark = addBookmark(dataManager: dataManager)

            let success = await dataManager.bookmarks.update(bookmark: bookmark, title: "title2")
            XCTAssertTrue(success, "\(impl): update should succeed")
        }
    }

    func testUpdatingTheTitleSaves() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let title1 = "First Title"
            let title2 = "Second Title"
            let modified = Date(timeIntervalSince1970: 10)

            let bookmark = addBookmark(title: title1, dataManager: dataManager)

            await dataManager.bookmarks.update(bookmark: bookmark, title: title2, modified: modified)

            let updatedBookmark = dataManager.bookmarks.bookmark(for: bookmark.uuid)
            XCTAssertEqual(updatedBookmark?.title, title2, "\(impl): title should update")
            XCTAssertEqual(updatedBookmark?.titleModified, modified, "\(impl): modified should update")
        }
    }

    func testUpdatingTitleEffectsOnlyOneBookmark() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let titles = ["a_title", "b_title", "c_title", "d_title"].sorted()

            let bookmarks = titles.map { addBookmark(episodeUuid: $0, title: $0, dataManager: dataManager) }
            let bookmarkToChange = 2
            let title2 = "c_title_2"

            await dataManager.bookmarks.update(bookmark: bookmarks[bookmarkToChange], title: title2)

            let updatedTitles = dataManager.bookmarks.allBookmarks().map { $0.title }.sorted()
            XCTAssertNotEqual(titles, updatedTitles, "\(impl): titles should differ after update")
            XCTAssertEqual(updatedTitles[bookmarkToChange], title2, "\(impl): only targeted bookmark should change")
        }
    }

    // MARK: - Deletion

    func testRemovingBookmarksSucceeds() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let bookmark = addBookmark(dataManager: dataManager)
            let success = await dataManager.bookmarks.remove(bookmarks: [bookmark])
            XCTAssertTrue(success, "\(impl): removal should succeed")
        }
    }

    func testRemovedBookmarksArentReturned() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let bookmark = addBookmark(dataManager: dataManager)
            _ = await dataManager.bookmarks.remove(bookmarks: [bookmark])

            XCTAssertNil(dataManager.bookmarks.bookmark(for: bookmark.uuid), "\(impl): removed bookmark should not be returned")
        }
    }

    func testAllBookmarksAlsoReturnsDeletedItems() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let bookmarkNotDeleted = addBookmark(time: 1, dataManager: dataManager)
            let bookmark = addBookmark(time: 2, dataManager: dataManager)

            _ = await dataManager.bookmarks.remove(bookmarks: [bookmark])
            let allBookmarks = dataManager.bookmarks.allBookmarks(includeDeleted: true, sorted: .timestamp)

            XCTAssertEqual([bookmarkNotDeleted.uuid, bookmark.uuid], allBookmarks.map(\.uuid), "\(impl): should return deleted and active")
        }
    }

    func testBookmarkIsPermanentlyRemoved() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let bookmark = addBookmark(dataManager: dataManager)
            let success = await dataManager.bookmarks.permanentlyDelete(bookmarks: [bookmark])
            XCTAssertTrue(success, "\(impl): permanent delete should succeed")

            XCTAssertTrue(dataManager.bookmarks.allBookmarks(includeDeleted: true).isEmpty, "\(impl): table should be empty")
        }
    }

    // MARK: - Sorting

    func testNewestToOldestSorting() throws {
        try runWithBothImplementations { dataManager, impl in
            let episode = "episode"

            let ordered = [(0, 0), (1, 10), (2, 20), (3, 30)].map { values in
                addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1), dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forEpisode: episode, sorted: .newestToOldest)

            XCTAssertEqual(ordered.reversed(), bookmarks, "\(impl): should be sorted newest to oldest")
        }
    }

    func testOldestToNewestSorting() throws {
        try runWithBothImplementations { dataManager, impl in
            let episode = "episode"

            let ordered = [(0, 0), (1, 10), (2, 20), (3, 30)].map { values in
                addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1), dataManager: dataManager)
            }

            let bookmarks = dataManager.bookmarks.bookmarks(forEpisode: episode, sorted: .oldestToNewest)

            XCTAssertEqual(ordered, bookmarks, "\(impl): should be sorted oldest to newest")
        }
    }

    func testTimestampSorting() throws {
        try runWithBothImplementations { dataManager, impl in
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

            XCTAssertEqual(ordered, bookmarks, "\(impl): should be sorted by timestamp")
        }
    }

    // MARK: - Syncing

    func testBookmarksToSyncReturnsOnlyItemsThatNeedSyncing() throws {
        try runWithBothImplementations { dataManager, impl in
            let count = 10

            for i in 0..<count {
                addBookmark(time: TimeInterval(i), dataManager: dataManager)
            }

            addBookmark(time: TimeInterval(999), syncStatus: .synced, dataManager: dataManager)

            let unsyncedBookmarks = dataManager.bookmarks.bookmarksToSync()
            XCTAssertEqual(unsyncedBookmarks.count, count, "\(impl): only unsynced should be returned")
        }
    }

    func testUpdatingTitleMarksAsNotSynced() async throws {
        try await runWithBothImplementations { dataManager, impl in
            addBookmark(time: TimeInterval(123), syncStatus: .synced, dataManager: dataManager)

            let bookmark = addBookmark(time: TimeInterval(999), syncStatus: .synced, dataManager: dataManager)
            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title")

            XCTAssertEqual(dataManager.bookmarks.bookmarksToSync().count, 1, "\(impl): update should mark bookmark as needing sync")
        }
    }

    func testUpdatingTitleUpdatesTheModifiedDate() async throws {
        try await runWithBothImplementations { dataManager, impl in
            let created = Date(timeIntervalSince1970: 1234)
            let bookmark = addBookmark(time: TimeInterval(999), created: created, syncStatus: .synced, dataManager: dataManager)
            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title")

            let updatedBookmark = dataManager.bookmarks.bookmark(for: bookmark.uuid)

            XCTAssertNotEqual(updatedBookmark?.titleModified, created, "\(impl): modified date should update")
        }
    }

    func testUpdatingWithSyncStatusSetsCorrectly() async throws {
        try await runWithBothImplementations { dataManager, impl in
            addBookmark(time: TimeInterval(123), syncStatus: .synced, dataManager: dataManager)
            let bookmark = addBookmark(time: TimeInterval(999), dataManager: dataManager)
            await dataManager.bookmarks.update(bookmark: bookmark, title: "New Title", syncStatus: .synced)

            XCTAssertEqual(dataManager.bookmarks.bookmarksToSync().count, 0, "\(impl): syncStatus should be updated")
        }
    }

    func testDeletingUpdatesSyncStatus() async throws {
        try await runWithBothImplementations { dataManager, impl in
            addBookmark(time: TimeInterval(123), syncStatus: .synced, dataManager: dataManager)
            let bookmark = addBookmark(time: TimeInterval(999), syncStatus: .synced, dataManager: dataManager)
            _ = await dataManager.bookmarks.remove(bookmarks: [bookmark])

            XCTAssertEqual(dataManager.bookmarks.bookmarksToSync().count, 1, "\(impl): delete should mark for sync")
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
