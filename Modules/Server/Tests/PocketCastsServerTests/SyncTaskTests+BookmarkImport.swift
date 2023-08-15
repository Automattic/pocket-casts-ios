@testable import PocketCastsServer
import PocketCastsDataModel
import FMDB
import XCTest

final class SyncTaskTests_BookmarkImport: XCTestCase {
    private var dataManager: DataManager!
    private var bookmarkManager: BookmarkDataManager!
    private var syncTask: SyncTask!

    override func setUp() {
        dataManager = DataManager(dbQueue: FMDatabaseQueue(), shouldCloseQueueAfterSetup: false)
        dataManager.bookmarksEnabled = true
        bookmarkManager = dataManager.bookmarks
        syncTask = SyncTask(dataManager: dataManager)
    }

    // MARK: - Importing a single bookmark

    func testNonexistingBookmarkIsAdded() async {
        let uuid = UUID().uuidString
        let episode = UUID().uuidString
        let podcast = UUID().uuidString
        let title = "Hello World"
        let time = 86400.0
        let created = Date(timeIntervalSince1970: 456)

        let apiBookmark = Api_SyncUserBookmark(uuid: uuid,
                                               episode: episode,
                                               podcast: podcast,
                                               title: title,
                                               time: time,
                                               created: created)

        await syncTask.importBookmark(apiBookmark)

        XCTAssertEqual(bookmarkManager.allBookmarks().count, 1)

        let bookmark = bookmarkManager.bookmark(for: uuid)

        XCTAssertNotNil(bookmark)
        XCTAssertEqual(created, bookmark?.created)
        XCTAssertEqual(episode, bookmark?.episodeUuid)
        XCTAssertEqual(podcast, bookmark?.podcastUuid)
        XCTAssertEqual(time, bookmark?.time)
        XCTAssertEqual(title, bookmark?.title)
    }

    func testNonexistingDeletedBookmarkIsNotAdded() async {
        let apiBookmark = Api_SyncUserBookmark(uuid: "nope", isDeleted: true)

        await syncTask.importBookmark(apiBookmark)

        XCTAssertNil(bookmarkManager.bookmark(for: "nope"))
    }

    func testExistingBookmarkGetsDeleted() async {
        // Add some bookmarks to the local db
        addBookmark(time: 1)
        let bookmark = addBookmark(time: 2)
        addBookmark(time: 3)
        addBookmark(time: 4)

        // Delete the bookmark from the API data
        let apiBookmark = Api_SyncUserBookmark.fromBookmark(bookmark, isDeleted: true)
        await syncTask.importBookmark(apiBookmark)

        // Ensure the bookmark was deleted
        let bookmarks = bookmarkManager.allBookmarks(sorted: .timestamp)
        XCTAssertEqual(bookmarks.count, 3)

        // Ensure the correct bookmark was removed
        XCTAssertEqual(bookmarks.map(\.time), [1, 3, 4])
    }

    func testExistingBookmarkGetsUpdated() async {
        // Add some bookmarks to the local db
        addBookmark(time: 1)
        let bookmark = addBookmark(time: 2)
        addBookmark(time: 3)
        addBookmark(time: 4)

        let uuid = bookmark.uuid
        let updatedTitle = "hello"
        let updatedTime = 321.0
        let updatedDate = Date.init(timeIntervalSince1970: 99999)

        let apiBookmark = Api_SyncUserBookmark(uuid: uuid,
                                               episode: bookmark.episodeUuid,
                                               podcast: bookmark.podcastUuid,
                                               title: updatedTitle,
                                               time: updatedTime,
                                               created: updatedDate)

        await syncTask.importBookmark(apiBookmark)

        // Ensure no bookmarks were deleted
        XCTAssertEqual(bookmarkManager.allBookmarks().count, 4)

        // Verify the updated data is saved
        let dbBookmark = bookmarkManager.bookmark(for: uuid)
        XCTAssertNotNil(bookmark)
        XCTAssertEqual(updatedDate, dbBookmark?.created)
        XCTAssertEqual(updatedTime, dbBookmark?.time)
        XCTAssertEqual(updatedTitle, dbBookmark?.title)
    }

    // MARK: - Server Data Processed

    func testProcessServerDataParsesBookmarksCorrectly() {
        let count = 2000
        let deletedCount = 321
        syncTask.processServerData(response: .bookmarkResponse(count: count, deletedCount: deletedCount))

        XCTAssertEqual(bookmarkManager.allBookmarks().count, count - deletedCount)
    }

    func testBookmarksArentSyncedIfFeatureFlagIsOff() {
        dataManager.bookmarksEnabled = false
        syncTask.processServerData(response: .bookmarkResponse(count: 20, deletedCount: 4))

        XCTAssertEqual(bookmarkManager.allBookmarks().count, 0)
    }
}

private extension SyncTaskTests_BookmarkImport {
    @discardableResult
    func addBookmark(episodeUuid: String = "episode-1",
                     podcastUuid: String = "podcast-uuid",
                     title: String = "Title",
                     time: TimeInterval = 1,
                     created: Date = .now) -> Bookmark {
        bookmarkManager.add(episodeUuid: episodeUuid, podcastUuid: podcastUuid, title: title, time: time, dateCreated: created).flatMap {
            bookmarkManager.bookmark(for: $0)
        }!
    }
}

private extension Api_SyncUpdateResponse {
    static func bookmarkResponse(count: Int, deletedCount: Int = 0) -> Self {
        var response = Api_SyncUpdateResponse()

        for i in 0..<count {
            let bookmark = Api_SyncUserBookmark(uuid: "uuid_\(i)",
                                                episode: "episode_\(i)",
                                                podcast: "podcast_\(i)",
                                                title: "title_\(i)",
                                                time: TimeInterval(i),
                                                created: .init(timeIntervalSince1970: TimeInterval(i)),
                                                isDeleted: i < deletedCount)

            var record = Api_Record()
            record.record = .bookmark(bookmark)
            record.bookmark = bookmark

            response.records.append(record)
        }

        return response
    }
}

private extension Api_SyncUserBookmark {
    static func fromBookmark(_ bookmark: Bookmark, isDeleted: Bool? = nil) -> Self {
        return .init(uuid: bookmark.uuid,
                     episode: bookmark.episodeUuid,
                     podcast: bookmark.podcastUuid,
                     title: bookmark.title,
                     time: bookmark.time,
                     created: bookmark.created,
                     isDeleted: isDeleted)
    }

    init(uuid: String,
         episode: String = "episode",
         podcast: String? = nil,
         title: String = "Title",
         time: TimeInterval = 1234,
         created: Date = Date(),
         isDeleted: Bool? = nil) {
        self.init()

        bookmarkUuid = uuid
        episodeUuid = episode

        if let podcast {
            podcastUuid = podcast
        }

        self.title.value = title
        self.time.value = Int32(time)
        createdAt = .init(date: created)

        if let isDeleted {
            self.isDeleted.value = isDeleted
        }
    }
}
