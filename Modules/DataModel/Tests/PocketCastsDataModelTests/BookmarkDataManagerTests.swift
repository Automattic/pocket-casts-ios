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

    func testAddBookmarkSucceeds() {
        XCTAssertNotNil(dataManager.add(episodeUuid: "episode-uuid", podcastUuid: "podcast-uuid", time: 1))
    }

    func testAddingEpisodeOnlyBookmarkSucceeds() {
        let episode = "episode-uuid"

        let result = dataManager.add(episodeUuid: episode, podcastUuid: nil, time: 1)
        XCTAssertNotNil(result)
        XCTAssertEqual(dataManager.bookmarks(forEpisode: episode).count, 1)
    }

    func testAddingExistingBookmarkIsNotAdded() {
        let episode = "episode-uuid"
        let podcast = "podcast-uuid"
        let time = 1.0

        let firstUuid = dataManager.add(episodeUuid: episode, podcastUuid: podcast, time: time)
        let secondUuid = dataManager.add(episodeUuid: episode, podcastUuid: podcast, time: time)

        XCTAssertEqual(firstUuid, secondUuid)
    }

    func testGettingAllBookmarksForPodcast() {
        let podcast = "podcast-uuid"

        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, time: 1)
        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, time: 3)

        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, time: 1)
        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, time: 3)

        let bookmarks = dataManager.bookmarks(forPodcast: podcast)
        XCTAssertEqual(bookmarks.count, 4)
    }

    func testGettingAllBookmarksForPodcastAndEpisode() {
        let podcast = "podcast-uuid"

        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, time: 1)
        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, time: 3)

        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, time: 1)
        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, time: 3)

        let bookmarks = dataManager.bookmarks(forPodcast: podcast, episodeUuid: "episode-2")
        XCTAssertEqual(bookmarks.count, 2)
    }

    // MARK: - Deletion

    func testRemovingBookmarksSucceeds() async {
        let bookmark = dataManager.add(episodeUuid: "episode-1", podcastUuid: "podcast-uuid", time: 1).flatMap {
            dataManager.bookmark(for: $0)
        }!

        let success = await dataManager.remove(bookmarks: [bookmark])
        XCTAssertTrue(success)
    }

    func testRemovedBookmarksArentReturned() async {
        let bookmark = dataManager.add(episodeUuid: "episode-1", podcastUuid: "podcast-uuid", time: 1).flatMap {
            dataManager.bookmark(for: $0)
        }!

        _ = await dataManager.remove(bookmarks: [bookmark])

        XCTAssertNil(dataManager.bookmark(for: bookmark.uuid))
    }

    func testAllBookmarksReturnsDeletedItems() async {
        let bookmark = dataManager.add(episodeUuid: "episode-1", podcastUuid: "podcast-uuid", time: 1).flatMap {
            dataManager.bookmark(for: $0)
        }!

        _ = await dataManager.remove(bookmarks: [bookmark])
        let allBookmarks = dataManager.allBookmarks(includeDeleted: true)

        XCTAssertEqual([bookmark.uuid], allBookmarks.map(\.uuid))
    }

    func testBookmarkIsPermanentlyRemoved() async {
        let bookmark = dataManager.add(episodeUuid: "episode-1", podcastUuid: "podcast-uuid", time: 1).flatMap {
            dataManager.bookmark(for: $0)
        }!

        let success = await dataManager.permanentlyDelete(bookmarks: [bookmark])
        XCTAssertTrue(success)

        XCTAssertTrue(dataManager.allBookmarks(includeDeleted: true).isEmpty)
    }
}
