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
        XCTAssertNotNil(dataManager.add(episodeUuid: "episode-uuid", podcastUuid: "podcast-uuid", start: 1, end: 2))
    }

    func testAddingEpisodeOnlyBookmarkSucceeds() {
        let episode = "episode-uuid"

        let result = dataManager.add(episodeUuid: episode, podcastUuid: nil, start: 1, end: 2)
        XCTAssertNotNil(result)
        XCTAssertEqual(dataManager.bookmarks(forEpisode: episode).count, 1)
    }

    func testAddingExistingBookmarkIsNotAdded() {
        let episode = "episode-uuid"
        let podcast = "podcast-uuid"
        let start = 1.0
        let end = 2.0

        let firstUuid = dataManager.add(episodeUuid: episode, podcastUuid: podcast, start: start, end: end)
        let secondUuid = dataManager.add(episodeUuid: episode, podcastUuid: podcast, start: start, end: end)

        XCTAssertEqual(firstUuid, secondUuid)
    }

    func testBookmarkModelReturnsCorrectTimeRange() {
        let start = 1.0
        let end = 2.0

        let uuid = dataManager.add(episodeUuid: "episode-uuid", podcastUuid: "podcast-uuid", start: start, end: end)
        let bookmark = dataManager.bookmark(for: uuid!)!

        XCTAssertEqual(bookmark.timeRange.start, start)
        XCTAssertEqual(bookmark.timeRange.end, end)
    }

    func testGettingAllBookmarksForPodcast() {
        let podcast = "podcast-uuid"

        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, start: 1, end: 2)
        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, start: 3, end: 4)

        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, start: 1, end: 2)
        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, start: 3, end: 4)

        let bookmarks = dataManager.bookmarks(forPodcast: podcast)
        XCTAssertEqual(bookmarks.count, 4)
    }

    func testGettingAllBookmarksForPodcastAndEpisode() {
        let podcast = "podcast-uuid"

        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, start: 1, end: 2)
        dataManager.add(episodeUuid: "episode-1", podcastUuid: podcast, start: 3, end: 4)

        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, start: 1, end: 2)
        dataManager.add(episodeUuid: "episode-2", podcastUuid: podcast, start: 3, end: 4)

        let bookmarks = dataManager.bookmarks(forPodcast: podcast, episodeUuid: "episode-2")
        XCTAssertEqual(bookmarks.count, 2)
    }
}
