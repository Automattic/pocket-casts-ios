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

    func testAnExpiredListIsRefreshingUntilTheNetworkAnswers() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))
        respond(withListTitled: "Fresh")
        XCTAssertEqual(handler.refreshStatus(of: [path]), DiscoverServerHandler.RefreshStatus(isRefreshing: false, lastRefreshed: nil))

        handler.discoverPodcastList(source: path, authenticated: false) { _ in }

        let status = handler.refreshStatus(of: [path])
        XCTAssertTrue(status.isRefreshing)
        XCTAssertNil(status.lastRefreshed)

        wait(for: [refreshFinishes()], timeout: 5)
        let finished = handler.refreshStatus(of: [path])
        XCTAssertFalse(finished.isRefreshing)
        XCTAssertNotNil(finished.lastRefreshed)
        XCTAssertEqual(cachedTitle(), "Fresh")
    }

    func testAFailedRefreshKeepsTheCachedListAndDoesntCountAsRefreshed() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))
        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        handler.discoverPodcastList(source: path, authenticated: false) { _ in }

        wait(for: [refreshFinishes()], timeout: 5)
        let status = handler.refreshStatus(of: [path])
        XCTAssertFalse(status.isRefreshing)
        XCTAssertNil(status.lastRefreshed)
        XCTAssertEqual(cachedTitle(), "Cached")
    }

    func testAListRequestedWhileItRefreshesDoesntStartAnotherRefresh() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))
        respond(withListTitled: "Fresh")

        handler.discoverPodcastList(source: path, authenticated: false) { _ in }
        handler.discoverPodcastList(source: path, authenticated: false) { _ in }

        wait(for: [refreshFinishes()], timeout: 5)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
    }

    func testAListThatWasJustRefreshedIsntRefreshedAgainEvenIfItsResponseIsAlreadyExpired() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))
        respond(withListTitled: "Fresh", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))

        handler.discoverPodcastList(source: path, authenticated: false) { _ in }
        wait(for: [refreshFinishes()], timeout: 5)

        var delivered: [String?] = []
        handler.discoverPodcastList(source: path, authenticated: false) { delivered.append($0?.title) }

        XCTAssertEqual(delivered, ["Fresh"])
        XCTAssertFalse(handler.refreshStatus(of: [path]).isRefreshing)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
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

    func testAnExpiredSignedInListCountsOnlyForTheAccountThatLoadedIt() {
        let previousUserID = ServerSettings.userId
        defer { ServerSettings.userId = previousUserID }

        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60), userID: "account-a")
        let item = DiscoverItem(source: path, regions: ["us"], authenticated: true)

        ServerSettings.userId = "account-a"
        XCTAssertTrue(handler.hasCachedContent(for: item))

        ServerSettings.userId = "account-b"
        XCTAssertFalse(handler.hasCachedContent(for: item), "Another account's recommendations are never shown")
    }

    func testAnExpiredListCountsForEveryAccount() {
        storeList(title: "Cached", fetched: Date(timeIntervalSinceNow: -2 * 60 * 60))

        XCTAssertTrue(handler.hasCachedContent(for: DiscoverItem(source: path, regions: ["us"])))
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

    private func storeList(title: String, fetched: Date, userID: String? = nil) {
        let url = ServerHelper.asUrl(path)
        let userInfo = userID.map { [DiscoverServerHandler.userIDKey: $0] }
        let cachedResponse = CachedURLResponse(response: response(url: url, date: fetched), data: listJSON(title: title), userInfo: userInfo, storagePolicy: .allowed)
        cache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
    }

    private func respond(withListTitled title: String, fetched: Date = Date()) {
        StubURLProtocol.requestHandler = { [unowned self] request in
            (response(url: request.url!, date: fetched), listJSON(title: title))
        }
    }

    private func refreshFinishes() -> XCTestExpectation {
        expectation(for: NSPredicate { [unowned self] _, _ in
            let status = handler.refreshStatus(of: [path])
            return !status.isRefreshing
        }, evaluatedWith: nil)
    }

    private func cachedTitle() -> String? {
        guard let data = cache.cachedResponse(for: URLRequest(url: ServerHelper.asUrl(path)))?.data else { return nil }
        return try? JSONDecoder().decode(PodcastList.self, from: data).title
    }
}
