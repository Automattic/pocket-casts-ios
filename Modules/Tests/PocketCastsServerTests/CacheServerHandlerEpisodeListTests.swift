@testable import PocketCastsServer
import XCTest

final class CacheServerHandlerEpisodeListTests: XCTestCase {
    private let podcastUuid = "e7a6f7d0-02f2-0133-1c51-059c869cc4eb"
    private let episodeListUrl = URL(string: "https://podcasts.pocketcasts.com/e7a6f7d0-02f2-0133-1c51-059c869cc4eb/episodes_full_1794005323.json")!
    private let lastModified = "Fri, 06 Nov 2026 22:48:44 GMT"

    private var requests: [URLRequest] = []

    private func makeHandler(respond: @escaping (URLRequest) throws -> (Data?, URLResponse?)) -> CacheServerHandler {
        let connection = URLConnection(mockHandler: { [unowned self] request in
            requests.append(request)
            return try respond(request)
        })
        return CacheServerHandler(tokenHelper: TokenHelper(urlConnection: connection), urlConnection: connection)
    }

    private func response(_ request: URLRequest, status: Int, headers: [String: String]? = nil) -> HTTPURLResponse? {
        HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)
    }

    private func podcastJson() throws -> Data {
        try JSONSerialization.data(withJSONObject: ["podcast": ["uuid": podcastUuid, "title": "A podcast", "episodes": [["uuid": "episode"]]]])
    }

    // MARK: - Episode list URLs

    func testLoadEpisodeListUrlsLooksUpEveryPodcastInOneRequest() throws {
        let handler = makeHandler { request in
            let json = """
            {"podcasts": [{"uuid": "one", "url": "https://podcasts.pocketcasts.com/one/episodes_full_1.json"}, {"uuid": "two", "url": "https://podcasts.pocketcasts.com/two/episodes_full_2.json"}]}
            """
            return (Data(json.utf8), self.response(request, status: 200))
        }

        let urls = loadEpisodeListUrls(handler, podcastUuids: ["one", "two", "unknown"])

        XCTAssertEqual(urls, [
            "one": URL(string: "https://podcasts.pocketcasts.com/one/episodes_full_1.json")!,
            "two": URL(string: "https://podcasts.pocketcasts.com/two/episodes_full_2.json")!
        ])
        XCTAssertEqual(requests.count, 1)
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, ServerConstants.Urls.cache() + "podcasts/update")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: [[String: String]]])
        XCTAssertEqual(body, ["podcasts": [["uuid": "one"], ["uuid": "two"], ["uuid": "unknown"]]])
    }

    func testLoadEpisodeListUrlsReturnsNoneWhenTheRequestFails() {
        let handler = makeHandler { request in
            (nil, self.response(request, status: 500))
        }

        XCTAssertEqual(loadEpisodeListUrls(handler, podcastUuids: ["one"]), [:])
    }

    func testLoadEpisodeListUrlsReturnsNoneWhenTheResponseIsInvalid() {
        let handler = makeHandler { request in
            (Data("{\"error\": true}".utf8), self.response(request, status: 200))
        }

        XCTAssertEqual(loadEpisodeListUrls(handler, podcastUuids: ["one"]), [:])
    }

    // MARK: - Podcast info

    func testLoadPodcastInfoLoadsTheEpisodeListDirectly() throws {
        let handler = makeHandler { request in
            (try self.podcastJson(), self.response(request, status: 200, headers: ["Last-Modified": self.lastModified]))
        }

        let (podcastInfo, lastModified) = loadPodcastInfo(handler, episodeListUrl: episodeListUrl)

        XCTAssertEqual((podcastInfo?["podcast"] as? [String: Any])?["title"] as? String, "A podcast")
        XCTAssertEqual(lastModified, self.lastModified)
        XCTAssertEqual(requests.map(\.url), [episodeListUrl])
        XCTAssertEqual(requests.first?.httpMethod, "GET")
        XCTAssertNil(requests.first?.value(forHTTPHeaderField: "Authorization"))
    }

    func testLoadPodcastInfoFallsBackToTheCacheServerWhenTheEpisodeListFails() throws {
        let handler = makeHandler { request in
            if request.url == self.episodeListUrl {
                return (Data("<Error/>".utf8), self.response(request, status: 403))
            }
            return (try self.podcastJson(), self.response(request, status: 200, headers: ["Last-Modified": self.lastModified]))
        }

        let (podcastInfo, lastModified) = loadPodcastInfo(handler, episodeListUrl: episodeListUrl)

        XCTAssertNotNil(podcastInfo)
        XCTAssertEqual(lastModified, self.lastModified)
        XCTAssertEqual(requests.map(\.url?.absoluteString), [
            episodeListUrl.absoluteString,
            ServerConstants.Urls.cache() + "mobile/podcast/full/\(podcastUuid)"
        ])
    }

    func testLoadPodcastInfoWithoutAnEpisodeListUrlUsesTheCacheServer() throws {
        let handler = makeHandler { request in
            (try self.podcastJson(), self.response(request, status: 200, headers: ["Last-Modified": self.lastModified]))
        }

        let (podcastInfo, lastModified) = loadPodcastInfo(handler, episodeListUrl: nil)

        XCTAssertNotNil(podcastInfo)
        XCTAssertEqual(lastModified, self.lastModified)
        XCTAssertEqual(requests.map(\.url?.absoluteString), [ServerConstants.Urls.cache() + "mobile/podcast/full/\(podcastUuid)"])
    }

    // MARK: - Helpers

    private func loadEpisodeListUrls(_ handler: CacheServerHandler, podcastUuids: [String]) -> [String: URL] {
        let expectation = expectation(description: "episode list URLs")
        var result: [String: URL] = [:]
        handler.loadEpisodeListUrls(podcastUuids: podcastUuids) { urls in
            result = urls
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result
    }

    private func loadPodcastInfo(_ handler: CacheServerHandler, episodeListUrl: URL?) -> ([String: Any]?, String?) {
        let expectation = expectation(description: "podcast info")
        var result: ([String: Any]?, String?) = (nil, nil)
        handler.loadPodcastInfo(podcastUuid: podcastUuid, episodeListUrl: episodeListUrl) { podcastInfo, lastModified in
            result = (podcastInfo, lastModified)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result
    }
}
