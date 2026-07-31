@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB

final class SyncTaskTests_BookmarkImport: XCTestCase {
    private var dataManager: DataManager!
    private var bookmarkManager: BookmarkDataManager!
    private var syncTask: SyncTask!

    override func setUp() {
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try! DatabasePool(path: NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite"))))
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
        let updatedDate = Date(timeIntervalSince1970: 99999)

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

    // MARK: - Passage Fields

    func testImportingNewBookmarkSavesPassageFields() async {
        let uuid = UUID().uuidString
        let passageModified = Date(timeIntervalSince1970: 100)
        let referenceTimeModified = Date(timeIntervalSince1970: 200)

        let apiBookmark = Api_SyncUserBookmark(uuid: uuid,
                                               passage: "A memorable passage",
                                               passageLocation: 4,
                                               passageModified: passageModified,
                                               referenceTime: 118,
                                               referenceTimeModified: referenceTimeModified)

        await syncTask.importBookmark(apiBookmark)

        let bookmark = bookmarkManager.bookmark(for: uuid)
        XCTAssertEqual(bookmark?.passage, "A memorable passage")
        XCTAssertEqual(bookmark?.passageLocation, 4)
        XCTAssertEqual(bookmark?.passageModified, passageModified)
        XCTAssertEqual(bookmark?.referenceTime, 118)
        XCTAssertEqual(bookmark?.referenceTimeModified, referenceTimeModified)
    }

    func testImportingExistingBookmarkUpdatesPassageFields() async {
        let bookmark = addBookmark(time: 2)
        let passageModified = Date(timeIntervalSince1970: 100)

        let apiBookmark = Api_SyncUserBookmark(uuid: bookmark.uuid,
                                               episode: bookmark.episodeUuid,
                                               podcast: bookmark.podcastUuid,
                                               title: bookmark.title,
                                               time: bookmark.time,
                                               created: bookmark.created,
                                               passage: "Synced passage",
                                               passageLocation: 7,
                                               passageModified: passageModified)

        await syncTask.importBookmark(apiBookmark)

        let updated = bookmarkManager.bookmark(for: bookmark.uuid)
        XCTAssertEqual(updated?.passage, "Synced passage")
        XCTAssertEqual(updated?.passageLocation, 7)
        XCTAssertEqual(updated?.passageModified, passageModified)
        XCTAssertNil(updated?.referenceTime, "An absent reference time group should stay nil")
    }

    func testImportingBookmarkWithoutPassageFieldsLeavesLocalValues() async {
        let passageModified = Date(timeIntervalSince1970: 100)
        let uuid = bookmarkManager.add(episodeUuid: "episode-1",
                                       podcastUuid: "podcast-uuid",
                                       title: "Title",
                                       time: 1,
                                       passage: "Local passage",
                                       passageLocation: 2,
                                       passageModified: passageModified,
                                       referenceTime: 30,
                                       referenceTimeModified: passageModified)!

        let apiBookmark = Api_SyncUserBookmark(uuid: uuid,
                                               episode: "episode-1",
                                               podcast: "podcast-uuid",
                                               title: "New Title",
                                               time: 1,
                                               created: Date(timeIntervalSince1970: 456))

        await syncTask.importBookmark(apiBookmark)

        let updated = bookmarkManager.bookmark(for: uuid)
        XCTAssertEqual(updated?.title, "New Title")
        XCTAssertEqual(updated?.passage, "Local passage", "An absent passage group should leave the local passage")
        XCTAssertEqual(updated?.passageLocation, 2)
        XCTAssertEqual(updated?.referenceTime, 30)
    }

    func testChangedBookmarksIncludePassageFieldsWhenSet() {
        let passageModified = Date(timeIntervalSince1970: 100)
        let referenceTimeModified = Date(timeIntervalSince1970: 200)
        bookmarkManager.add(episodeUuid: "episode-1",
                            podcastUuid: "podcast-uuid",
                            title: "Title",
                            time: 1,
                            passage: "Local passage",
                            passageLocation: 2,
                            passageModified: passageModified,
                            referenceTime: 30,
                            referenceTimeModified: referenceTimeModified)

        let record = syncTask.changedBookmarks()?.first?.bookmark

        XCTAssertNotNil(record)
        XCTAssertEqual(record?.passage.value, "Local passage")
        XCTAssertEqual(record?.passageLocation.value, 2)
        XCTAssertEqual(record?.passageModified.value, 100_000, "The modified date should upload as epoch milliseconds")
        XCTAssertEqual(record?.referenceTime.value, 30)
        XCTAssertEqual(record?.referenceTimeModified.value, 200_000, "The modified date should upload as epoch milliseconds")
    }

    func testChangedBookmarksOmitPassageFieldsWhenNeverSet() {
        addBookmark(time: 1)

        let record = syncTask.changedBookmarks()?.first?.bookmark

        XCTAssertNotNil(record)
        XCTAssertFalse(record?.hasPassage ?? true, "The passage group should not upload when it was never set")
        XCTAssertFalse(record?.hasPassageLocation ?? true)
        XCTAssertFalse(record?.hasPassageModified ?? true)
        XCTAssertFalse(record?.hasReferenceTime ?? true, "The reference time group should not upload when it was never set")
        XCTAssertFalse(record?.hasReferenceTimeModified ?? true)
    }

    func testFullSyncKeepsLocalPassageFields() throws {
        let passageModified = Date(timeIntervalSince1970: 100)
        let uuid = try XCTUnwrap(bookmarkManager.add(episodeUuid: "episode-1",
                                                     podcastUuid: "podcast-uuid",
                                                     title: "Title",
                                                     time: 1,
                                                     passage: "Local passage",
                                                     passageLocation: 2,
                                                     passageModified: passageModified,
                                                     referenceTime: 30,
                                                     referenceTimeModified: passageModified))
        let bookmark = try XCTUnwrap(bookmarkManager.bookmark(for: uuid))

        syncTask.processServerBookmarks([.fromBookmark(bookmark)])

        let replaced = bookmarkManager.bookmark(for: uuid)
        XCTAssertEqual(replaced?.passage, "Local passage", "The passage fields should survive the full sync replacing the bookmark")
        XCTAssertEqual(replaced?.passageLocation, 2)
        XCTAssertEqual(replaced?.passageModified, passageModified)
        XCTAssertEqual(replaced?.referenceTime, 30)
        XCTAssertEqual(replaced?.referenceTimeModified, passageModified)
    }

    // MARK: - Server Data Processed

    func testProcessServerDataParsesBookmarksCorrectly() {
        let count = 2000
        let deletedCount = 321
        syncTask.processServerData(response: .bookmarkResponse(count: count, deletedCount: deletedCount))

        XCTAssertEqual(bookmarkManager.allBookmarks().count, count - deletedCount)
    }

    // MARK: - Full Sync

    func testFullSyncMarksAllAsSynced() {
        let bookmarks = [
            addBookmark(time: 1),
            addBookmark(time: 2),
            addBookmark(time: 3)
        ]

        let server = bookmarks.map {
            Api_BookmarkResponse.fromBookmark($0)
        }

        syncTask.processServerBookmarks(server)

        XCTAssertEqual(bookmarkManager.bookmarksToSync().count, 0)
    }

    func testFullSyncReplacesExistingUUIDs() {
        let bookmarks = [
            addBookmark(time: 1),
            addBookmark(time: 2),
            addBookmark(time: 3)
        ]

        let newTitle = "NEW TITLE"
        let created = Date(timeIntervalSince1970: 4321)

        let server = bookmarks.map {
            Api_BookmarkResponse.forTesting(uuid: $0.uuid, episode: $0.episodeUuid, podcast: $0.podcastUuid, title: newTitle, time: $0.time, created: created)
        }

        syncTask.processServerBookmarks(server)

        let allBookmarks = bookmarkManager.allBookmarks()

        XCTAssertEqual(allBookmarks.map(\.title), Array(repeating: newTitle, count: bookmarks.count))
        XCTAssertEqual(allBookmarks.map(\.created), Array(repeating: created, count: bookmarks.count))
    }

    func testFullSyncImportsDataCorrectly() {
        let serverData: [Api_BookmarkResponse] = [
            .forTesting(uuid: "one", episode: "two", podcast: "three", title: "four", time: 5, created: .init(timeIntervalSince1970: 6)),
            .forTesting(uuid: "seven", episode: "eight", podcast: "nine", title: "ten", time: 11, created: .init(timeIntervalSince1970: 12)),
            .forTesting(uuid: "thirteen", episode: "fourteen", podcast: "fifteen", title: "sixteen", time: 17, created: .init(timeIntervalSince1970: 18))
        ]

        syncTask.processServerBookmarks(serverData)

        let allBookmarks = bookmarkManager.allBookmarks(sorted: .timestamp)

        XCTAssertEqual(allBookmarks.count, serverData.count)
        XCTAssertEqual(allBookmarks.map(\.uuid), ["one", "seven", "thirteen"])
        XCTAssertEqual(allBookmarks.map(\.title), ["four", "ten", "sixteen"])
        XCTAssertEqual(allBookmarks.map(\.episodeUuid), ["two", "eight", "fourteen"])
        XCTAssertEqual(allBookmarks.map(\.podcastUuid), ["three", "nine", "fifteen"])
        XCTAssertEqual(allBookmarks.map(\.time), [5, 11, 17])
        XCTAssertEqual(allBookmarks.map(\.created), [.init(timeIntervalSince1970: 6), .init(timeIntervalSince1970: 12), .init(timeIntervalSince1970: 18)])
    }

    func testFullSyncIgnoresExistingItems() {
        addBookmark(time: 1)
        addBookmark(time: 2)
        addBookmark(time: 3)

        let serverData: [Api_BookmarkResponse] = [
            .forTesting(uuid: "one", episode: "two", podcast: "three", title: "four", time: 5, created: .init(timeIntervalSince1970: 6)),
            .forTesting(uuid: "seven", episode: "eight", podcast: "nine", title: "ten", time: 11, created: .init(timeIntervalSince1970: 12)),
            .forTesting(uuid: "thirteen", episode: "fourteen", podcast: "fifteen", title: "sixteen", time: 17, created: .init(timeIntervalSince1970: 18))
        ]

        syncTask.processServerBookmarks(serverData)

        XCTAssertEqual( bookmarkManager.allBookmarks().count, 6)
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
         isDeleted: Bool? = nil,
         passage: String? = nil,
         passageLocation: Int? = nil,
         passageModified: Date? = nil,
         referenceTime: TimeInterval? = nil,
         referenceTimeModified: Date? = nil) {
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

        // Mirror the server: a group is only present along with its modified timestamp,
        // with "" / 0 placeholders for null values within it
        if let passageModified {
            self.passage.value = passage ?? ""
            self.passageLocation.value = Int32(passageLocation ?? 0)
            self.passageModified = .init(date: passageModified)
        }

        if let referenceTimeModified {
            self.referenceTime.value = Int32(referenceTime ?? 0)
            self.referenceTimeModified = .init(date: referenceTimeModified)
        }
    }
}

private extension Api_BookmarkResponse {
    static func forTesting(uuid: String,
                           episode: String = "episode",
                           podcast: String? = nil,
                           title: String = "Title",
                           time: TimeInterval = 1234,
                           created: Date = Date()) -> Self {
        var apiBookmark = Api_BookmarkResponse()
        apiBookmark.bookmarkUuid = uuid
        apiBookmark.episodeUuid = episode

        if let podcast {
            apiBookmark.podcastUuid = podcast
        }

        apiBookmark.title = title
        apiBookmark.time = Int32(time)
        apiBookmark.createdAt = .init(date: created)

        return apiBookmark
    }

    static func fromBookmark(_ bookmark: Bookmark) -> Self {
        return forTesting(uuid: bookmark.uuid,
                          episode: bookmark.episodeUuid,
                          podcast: bookmark.podcastUuid,
                          title: bookmark.title,
                          time: bookmark.time,
                          created: bookmark.created)
    }
}
