import Foundation
@testable import PocketCastsServer
import XCTest

final class DiscoverServerHandlerCacheTests: XCTestCase {
    private let path = "https://lists.pocketcasts.net/trending.json"
    private var cache: URLCache!
    private var handler: DiscoverServerHandler!

    override func setUp() {
        super.setUp()
        cache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 0, directory: nil)
        handler = DiscoverServerHandler(urlSession: StubURLProtocol.session(), discoveryCache: cache)
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testAnExpiredListIsServedRightAwayAndRefreshedInTheBackground() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))
        respond(withListTitled: "Fresh")

        var delivered: [String?] = []
        handler.discoverPodcastList(source: path, authenticated: false) { delivered.append($0?.title) }

        XCTAssertEqual(delivered, ["Cached"], "The expired list is delivered without waiting for the network")

        let refreshed = expectation(for: NSPredicate { [unowned self] _, _ in cachedTitle() == "Fresh" }, evaluatedWith: nil)
        wait(for: [refreshed], timeout: 5)
        XCTAssertEqual(delivered, ["Cached"], "The refreshed list is kept for the next request, not delivered again")
    }

    func testAFreshListIsServedWithoutANetworkRequest() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -60))
        respond(withListTitled: "Fresh")

        var delivered: [String?] = []
        handler.discoverPodcastList(source: path, authenticated: false) { delivered.append($0?.title) }

        XCTAssertEqual(delivered, ["Cached"])
        XCTAssertEqual(StubURLProtocol.requestCount, 0)
    }

    func testAListThatIsntCachedComesFromTheNetwork() {
        respond(withListTitled: "Fresh")

        let loaded = expectation(description: "The list loads")
        handler.discoverPodcastList(source: path, authenticated: false) { list in
            XCTAssertEqual(list?.title, "Fresh")
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 5)
        XCTAssertEqual(cachedTitle(), "Fresh")
    }

    // MARK: - Helpers

    private func listJSON(title: String) -> Data {
        Data(#"{"title": "\#(title)", "podcasts": [{"uuid": "c59b45b0-0bc4-012e-fb02-00163e1b201c", "title": "Planet Money"}]}"#.utf8)
    }

    private func response(url: URL, date: Date) -> HTTPURLResponse {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        let headers = ["Cache-Control": "max-age=1800", "Date": formatter.string(from: date)]
        return HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
    }

    private func storeList(title: String, fetched: Date) {
        let url = ServerHelper.asUrl(path)
        cache.storeCachedResponse(CachedURLResponse(response: response(url: url, date: fetched), data: listJSON(title: title)), for: URLRequest(url: url))
    }

    private func respond(withListTitled title: String) {
        StubURLProtocol.requestHandler = { [unowned self] request in
            (response(url: request.url!, date: Date()), listJSON(title: title))
        }
    }

    private func cachedTitle() -> String? {
        guard let data = cache.cachedResponse(for: URLRequest(url: ServerHelper.asUrl(path)))?.data else { return nil }
        return try? JSONDecoder().decode(PodcastList.self, from: data).title
    }
}
