import Combine
import Foundation
import PocketCastsUtils
@testable import PocketCastsServer
import XCTest

@MainActor
final class WhatsNewManagerTests: XCTestCase {
    private let messageID = "01K2Y08DAWG9N7XJZX5QTH9Z0K"
    private let otherMessageID = "01K2Y3D5J1H7QZP0B6RXKA4N3T"

    private let json = """
    {
      "schemaVersion": 1,
      "messages": [
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "tip",
          "publishedAt": "2026-08-17T08:00:00Z",
          "targeting": {},
          "title": "Sort your Up Next",
          "pages": [
            {
              "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
              "heading": "Put the queue in the order you want",
              "description": "…"
            }
          ]
        }
      ]
    }
    """

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testFetchesTheCatalogWhenThereIsNothingOnDisk() async {
        let manager = manager(cache: temporaryCache())
        XCTAssertNil(manager.catalog)

        await manager.refreshIfNeeded().value

        XCTAssertEqual(manager.catalog?.messages.map(\.title), ["Sort your Up Next"])
    }

    /// The feed and the unread state read the catalog straight off the manager, so it has to hold
    /// what the last session fetched before anything reaches the network.
    func testPublishesTheCatalogOnDiskWithoutGoingToTheNetwork() async {
        let cache = temporaryCache()
        cache.save(Data(json.utf8), forLocale: WhatsNewCatalogTask.currentLocale)

        let manager = manager(cache: cache)
        StubURLProtocol.requestHandler = { _ in
            XCTFail("A catalog written moments ago shouldn't be fetched again")
            throw URLError(.unknown)
        }

        await manager.refreshIfNeeded().value

        XCTAssertEqual(manager.catalog?.messages.map(\.title), ["Sort your Up Next"])
    }

    func testDoesNotFetchAgainWhileTheCopyOnDiskIsCurrent() async {
        let manager = manager(cache: temporaryCache())

        await manager.refreshIfNeeded().value
        await manager.refreshIfNeeded().value

        XCTAssertEqual(requestCount, 1, "Becoming active again inside the interval doesn't re-fetch the catalog")
    }

    func testFetchesAgainOnceTheCopyOnDiskHasAgedOut() async {
        let manager = manager(cache: temporaryCache(), refreshInterval: 0)

        await manager.refreshIfNeeded().value
        await manager.refreshIfNeeded().value

        XCTAssertEqual(requestCount, 2)
    }

    func testOverlappingRefreshesShareOneRequest() async {
        let manager = manager(cache: temporaryCache(), refreshInterval: 0)

        let first = manager.refreshIfNeeded()
        let second = manager.refreshIfNeeded()
        await first.value
        await second.value

        XCTAssertEqual(requestCount, 1)
    }

    /// Pulling to refresh the feed asks for the latest messages, however recently they were fetched.
    func testRefreshingFetchesWhileTheCopyOnDiskIsCurrent() async {
        let manager = manager(cache: temporaryCache())
        await manager.refreshIfNeeded().value

        await manager.refresh().value

        XCTAssertEqual(requestCount, 2)
    }

    /// The refresh already in flight may be about to find the copy on disk current and stop there.
    func testRefreshingJoinsTheRefreshInFlightAndStillFetches() async {
        let cache = temporaryCache()
        cache.save(Data(json.utf8), forLocale: WhatsNewCatalogTask.currentLocale)
        let manager = manager(cache: cache)

        let first = manager.refreshIfNeeded()
        let second = manager.refresh()
        await first.value
        await second.value

        XCTAssertEqual(requestCount, 1)
    }

    func testRefreshingDoesNotForceTheNextRefresh() async {
        let manager = manager(cache: temporaryCache())
        await manager.refresh().value

        await manager.refreshIfNeeded().value

        XCTAssertEqual(requestCount, 1)
    }

    /// Offline, the feed still has to show what it had rather than emptying itself out.
    func testKeepsTheCatalogItHasWhenTheRefreshFails() async {
        let manager = manager(cache: temporaryCache(), refreshInterval: 0)
        await manager.refreshIfNeeded().value

        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        await manager.refreshIfNeeded().value

        XCTAssertEqual(manager.catalog?.messages.map(\.title), ["Sort your Up Next"])
    }

    // MARK: - Read state

    /// Until read state syncs with the server, the file next to the catalog is all that remembers it.
    func testReadStateOutlivesTheManager() async {
        let store = temporaryReadStateStore()
        let manager = manager(cache: temporaryCache(), readStateStore: store)
        await manager.refreshIfNeeded().value

        manager.markAsRead([messageID])
        manager.markAsSeen([otherMessageID])
        manager.markAsListed([messageID])

        let relaunched = self.manager(cache: temporaryCache(), readStateStore: store)
        await relaunched.refreshIfNeeded().value

        XCTAssertEqual(relaunched.readState, WhatsNewReadState(readMessageIDs: [messageID],
                                                               seenMessageIDs: [messageID, otherMessageID],
                                                               listedMessageIDs: [messageID]))
    }

    /// The unread dots are drawn from the catalog and the read state together, so a message read in
    /// an earlier session can't be published as unread, even for a moment.
    func testReadStateIsInPlaceBeforeTheCatalogIsPublished() async {
        let cache = temporaryCache()
        cache.save(Data(json.utf8), forLocale: WhatsNewCatalogTask.currentLocale)
        let store = temporaryReadStateStore()
        store.save(WhatsNewReadState(readMessageIDs: [messageID]))

        let manager = manager(cache: cache, readStateStore: store)
        var readStateWhenPublished: WhatsNewReadState?
        let cancellable = manager.$catalog
            .compactMap { $0 }
            .sink { _ in readStateWhenPublished = manager.readState }

        await manager.refreshIfNeeded().value
        cancellable.cancel()

        XCTAssertEqual(readStateWhenPublished?.readMessageIDs, [messageID])
    }

    /// A message can be marked read before the first refresh has read the state back, and saving
    /// that on its own would replace every read before it.
    func testReadingBeforeTheStateIsLoadedKeepsWhatWasSaved() async {
        let store = temporaryReadStateStore()
        store.save(WhatsNewReadState(readMessageIDs: [messageID]))

        let manager = manager(cache: temporaryCache(), readStateStore: store)
        manager.markAsRead([otherMessageID])
        await manager.refreshIfNeeded().value

        XCTAssertEqual(manager.readState.readMessageIDs, [messageID, otherMessageID])
        XCTAssertEqual(store.load().readMessageIDs, [messageID, otherMessageID])
    }

    /// The Profile tab points the user at the feed, so once the feed has listed a message the tab has
    /// nothing left to point at.
    func testListingMessagesMarksThemSeen() async {
        let manager = manager(cache: temporaryCache())
        await manager.refreshIfNeeded().value

        manager.markAsListed([messageID])

        XCTAssertEqual(manager.readState, WhatsNewReadState(seenMessageIDs: [messageID], listedMessageIDs: [messageID]))
    }

    func testResettingForgetsEverythingReadSeenOrListed() async {
        let store = temporaryReadStateStore()
        let manager = manager(cache: temporaryCache(), readStateStore: store)
        await manager.refreshIfNeeded().value
        manager.markAsRead([messageID])
        manager.markAsSeen([otherMessageID])
        manager.markAsListed([messageID])

        manager.resetReadState()

        XCTAssertEqual(manager.readState, WhatsNewReadState())
        XCTAssertEqual(store.load(), WhatsNewReadState())
    }

    // MARK: - Helpers

    private var requestCount: Int { StubURLProtocol.requestCount }

    private func manager(cache: WhatsNewCatalogCache,
                         readStateStore: WhatsNewReadStateStore? = nil,
                         refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) -> WhatsNewManager {
        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let task = WhatsNewCatalogTask(session: StubURLProtocol.session(), cache: cache)
        return WhatsNewManager(task: task, readStateStore: readStateStore ?? temporaryReadStateStore(), refreshInterval: refreshInterval)
    }

    private func temporaryCache() -> WhatsNewCatalogCache {
        WhatsNewCatalogCache(directory: temporaryDirectory())
    }

    private func temporaryReadStateStore() -> WhatsNewReadStateStore {
        WhatsNewReadStateStore(directory: temporaryDirectory())
    }

    private func temporaryDirectory() -> URL {
        let directory = URL.temporaryDirectory.appending(path: "whats-new-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}
