@testable import PocketCastsDataModel

import FMDB
import XCTest

final class BookmarkDataManagerTests: XCTestCase {
    private var dbQueue: FMDatabaseQueue!
    private var dataManager: BookmarkDataManager!

    override func setUp(completion: @escaping (Error?) -> Void) {
        dbQueue = FMDatabaseQueue()

        // Create the schema
        // the inDatabase call doesn't let you throw, so we'll track if there's an error here then pass it to the completion
        var createError: Error? = nil
        dbQueue.inDatabase { db in
            do {
                try BookmarkDataManager.createTable(in: db)
            } catch {
                createError = error
            }
        }

        dataManager = BookmarkDataManager(dbQueue: dbQueue)
        completion(createError)
    }

    override func tearDown() {
        dbQueue.close()
    }

    // MARK: - Adding

    func testAddBookmarkSucceeds() {
        XCTAssertNotNil(dataManager.add(episodeUuid: "episode-uuid", podcastUuid: "podcast-uuid", title: "Title", time: 1))
    }

    func testAddingEpisodeOnlyBookmarkSucceeds() {
        let episode = "episode-uuid"

        addBookmark(episodeUuid: episode)
        XCTAssertEqual(dataManager.bookmarks(forEpisode: episode).count, 1)
    }

    func testAddingABookmarkAtTheSameTimeAsAnotherDoesntGetAdded() {
        let title = "Title 1"
        let date = Date(timeIntervalSince1970: 321)
        let time = 9876.0

        let first = dataManager.add(episodeUuid: "episode-uuid", podcastUuid: "podcast-uuid", title: title, time: time, dateCreated: date)

        let second = dataManager.add(episodeUuid: "episode-uuid", podcastUuid: "podcast-uuid", title: "Title 2", time: 9876, dateCreated: Date())

        XCTAssertNil(second)

        // Verify stored data was not modified
        let bookmark = dataManager.bookmark(for: first!)
        XCTAssertEqual(title, bookmark?.title)
        XCTAssertEqual(time, bookmark?.time)
        XCTAssertEqual(date, bookmark?.created)
    }

    // MARK: - Retrieving

    func testGettingAllBookmarksForPodcast() {
        let podcast = "podcast-uuid"

        ["episode-1", "episode-2"].forEach {
            addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 1)
            addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 3)
        }

        let bookmarks = dataManager.bookmarks(forPodcast: podcast)
        XCTAssertEqual(bookmarks.count, 4)
    }

    func testGettingAllBookmarksForPodcastAndEpisode() {
        let podcast = "podcast-uuid"

        ["episode-1", "episode-2"].forEach {
            addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 1)
            addBookmark(episodeUuid: $0, podcastUuid: podcast, time: 3)
        }

        let bookmarks = dataManager.bookmarks(forPodcast: podcast, episodeUuid: "episode-2")
        XCTAssertEqual(bookmarks.count, 2)
    }

    // MARK: - Counts
    func testBookmarkReturnsCorrectly() {
        let count = 10

        for i in 0..<count {
            addBookmark(episodeUuid: "episode", time: Double(i))
        }

        XCTAssertEqual(dataManager.bookmarkCount(forEpisode: "episode"), count)
    }

    func testDeletedBookmarksAreExcludedFromCount() async {
        let count = 10

        let deletedBookmark = addBookmark(episodeUuid: "episode", time: 1234)

        for i in 0..<count {
            addBookmark(episodeUuid: "episode", time: Double(i))
        }

        _ = await dataManager.remove(bookmarks: [deletedBookmark])

        XCTAssertEqual(dataManager.bookmarkCount(forEpisode: "episode"), count)
    }

    func testBookmarkCountCanIncludeDeletedItems() async {
        let count = 10

        let deletedBookmark = addBookmark(episodeUuid: "episode", time: 1234)

        for i in 0..<count {
            addBookmark(episodeUuid: "episode", time: Double(i))
        }

        _ = await dataManager.remove(bookmarks: [deletedBookmark])


        XCTAssertEqual(dataManager.bookmarkCount(forEpisode: "episode", includeDeleted: true), count + 1)
    }

    // MARK: - Data Validation

    func testBookmarkReturnsCorrectValues() {
        let created = Date(timeIntervalSince1970: 0)
        let episode = "episode-uuid"
        let podcast = "podcast-uuid"
        let time: TimeInterval = 12345
        let title = "Hello World"

        let bookmark = addBookmark(episodeUuid: episode, podcastUuid: podcast, title: title, time: time, created: created)

        XCTAssertEqual(bookmark.created, created)
        XCTAssertEqual(bookmark.episodeUuid, episode)
        XCTAssertEqual(bookmark.titleModified, created)
        XCTAssertEqual(bookmark.podcastUuid, podcast)
        XCTAssertEqual(bookmark.time, time)
        XCTAssertEqual(bookmark.title, title)
    }

    // MARK: - Updating

    func testUpdatingTitleSucceeds() async {
        let bookmark = addBookmark()

        let success = await dataManager.update(bookmark: bookmark, title: "title2")
        XCTAssertTrue(success)
    }

    func testUpdatingTheTitleSaves() async {
        let title1 = "First Title"
        let title2 = "Second Title"
        let modified = Date(timeIntervalSince1970: 10)

        let bookmark = addBookmark(title: title1)

        await dataManager.update(bookmark: bookmark, title: title2, modified: modified)

        let updatedBookmark = dataManager.bookmark(for: bookmark.uuid)
        XCTAssertEqual(updatedBookmark?.title, title2)
        XCTAssertEqual(updatedBookmark?.titleModified, modified)
    }

    func testUpdatingTitleEffectsOnlyOneBookmark() async {
        let titles = ["a_title", "b_title", "c_title", "d_title"].sorted()

        let bookmarks = titles.map { addBookmark(episodeUuid: $0, title: $0) }
        let bookmarkToChange = 2
        let title2 = "c_title_2"

        await dataManager.update(bookmark: bookmarks[bookmarkToChange], title: title2)

        let updatedTitles = dataManager.allBookmarks().map { $0.title }.sorted()
        XCTAssertNotEqual(titles, updatedTitles)
        XCTAssertEqual(updatedTitles[bookmarkToChange], title2)
    }

    // MARK: - Deletion

    func testRemovingBookmarksSucceeds() async {
        let bookmark = addBookmark()
        let success = await dataManager.remove(bookmarks: [bookmark])
        XCTAssertTrue(success)
    }

    func testRemovedBookmarksArentReturned() async {
        let bookmark = addBookmark()
        _ = await dataManager.remove(bookmarks: [bookmark])

        XCTAssertNil(dataManager.bookmark(for: bookmark.uuid))
    }

    func testAllBookmarksAlsoReturnsDeletedItems() async {
        let bookmarkNotDeleted = addBookmark(time: 1)
        let bookmark = addBookmark(time: 2)

        _ = await dataManager.remove(bookmarks: [bookmark])
        let allBookmarks = dataManager.allBookmarks(includeDeleted: true, sorted: .timestamp)

        XCTAssertEqual([bookmarkNotDeleted.uuid, bookmark.uuid], allBookmarks.map(\.uuid))
    }

    func testBookmarkIsPermanentlyRemoved() async {
        let bookmark = addBookmark()
        let success = await dataManager.permanentlyDelete(bookmarks: [bookmark])
        XCTAssertTrue(success)

        XCTAssertTrue(dataManager.allBookmarks(includeDeleted: true).isEmpty)
    }

    // MARK: - Sorting
    func testNewestToOldestSorting() {
        let episode = "episode"

        let ordered = [(0, 0), (1, 10), (2, 20), (3, 30)].map { values in
            addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1))
        }

        let bookmarks = dataManager.bookmarks(forEpisode: episode, sorted: .newestToOldest)

        XCTAssertEqual(ordered.reversed(), bookmarks)
    }

    func testOldestToNewestSorting() {
        let episode = "episode"

        let ordered = [(0, 0), (1, 10), (2, 20), (3, 30)].map { values in
            addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1))
        }

        let bookmarks = dataManager.bookmarks(forEpisode: episode, sorted: .oldestToNewest)

        XCTAssertEqual(ordered, bookmarks)
    }

    func testTimestampSorting() {
        let episode = "episode"

        let ordered = [(0, 24), (3600, 1), (7200, 123), (86400, 321)].map { values in
            addBookmark(episodeUuid: episode, time: values.0, created: .init(timeIntervalSince1970: values.1))
        }

        let bookmarks = dataManager.bookmarks(forEpisode: episode, sorted: .timestamp)

        XCTAssertEqual(ordered, bookmarks)
    }

    // MARK: - Syncing
    func testBookmarksToSyncReturnsOnlyItemsThatNeedSyncing() {
        let count = 10

        for i in 0..<count {
            addBookmark(time: TimeInterval(i))
        }

        addBookmark(time: TimeInterval(999), syncStatus: .synced)

        let unsyncedBookmarks = dataManager.bookmarksToSync()
        XCTAssertEqual(unsyncedBookmarks.count, count)
    }

    func testUpdatingTitleMarksAsNotSynced() async {
        addBookmark(time: TimeInterval(123), syncStatus: .synced)

        let bookmark = addBookmark(time: TimeInterval(999), syncStatus: .synced)
        await dataManager.update(bookmark: bookmark, title: "New Title")

        XCTAssertEqual(dataManager.bookmarksToSync().count, 1)
    }

    func testUpdatingTitleUpdatesTheModifiedDate() async {
        let created = Date(timeIntervalSince1970: 1234)
        let bookmark = addBookmark(time: TimeInterval(999), created: created, syncStatus: .synced)
        await dataManager.update(bookmark: bookmark, title: "New Title")

        let updatedBookmark = dataManager.bookmark(for: bookmark.uuid)

        XCTAssertNotEqual(updatedBookmark?.titleModified, created)
    }

    func testUpdatingWithSyncStatusSetsCorrectly() async {
        addBookmark(time: TimeInterval(123), syncStatus: .synced)
        let bookmark = addBookmark(time: TimeInterval(999))
        await dataManager.update(bookmark: bookmark, title: "New Title", syncStatus: .synced)

        XCTAssertEqual(dataManager.bookmarksToSync().count, 0)
    }

    func testDeletingUpdatesSyncStatus() async {
        addBookmark(time: TimeInterval(123), syncStatus: .synced)
        let bookmark = addBookmark(time: TimeInterval(999), syncStatus: .synced)
        _ = await dataManager.remove(bookmarks: [bookmark])

        XCTAssertEqual(dataManager.bookmarksToSync().count, 1)
    }
}

private extension BookmarkDataManagerTests {
    @discardableResult
    func addBookmark(episodeUuid: String = "episode-1", podcastUuid: String = "podcast-uuid", title: String = "Title", time: TimeInterval = 1, created: Date = .now, syncStatus: SyncStatus = .notSynced) -> Bookmark {
        dataManager.add(episodeUuid: episodeUuid, podcastUuid: podcastUuid, title: title, time: time, dateCreated: created, syncStatus: syncStatus).flatMap {
            dataManager.bookmark(for: $0)
        }!
    }
}
