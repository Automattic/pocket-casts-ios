import Foundation
import PocketCastsUtils
@testable import PocketCastsServer
import XCTest

@MainActor
final class WhatsNewManagerTests: XCTestCase {
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

    /// Offline, the feed still has to show what it had rather than emptying itself out.
    func testKeepsTheCatalogItHasWhenTheRefreshFails() async {
        let manager = manager(cache: temporaryCache(), refreshInterval: 0)
        await manager.refreshIfNeeded().value

        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        await manager.refreshIfNeeded().value

        XCTAssertEqual(manager.catalog?.messages.map(\.title), ["Sort your Up Next"])
    }

    // MARK: - Helpers

    private var requestCount: Int { StubURLProtocol.requestCount }

    private func manager(cache: WhatsNewCatalogCache,
                         refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) -> WhatsNewManager {
        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let task = WhatsNewCatalogTask(session: StubURLProtocol.session(), cache: cache)
        return WhatsNewManager(task: task, refreshInterval: refreshInterval)
    }

    private func temporaryCache() -> WhatsNewCatalogCache {
        let directory = URL.temporaryDirectory.appending(path: "whats-new-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return WhatsNewCatalogCache(directory: directory)
    }
}
