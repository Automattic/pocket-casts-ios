import PocketCastsServer
import XCTest

@testable import podcasts

@MainActor
final class WhatsNewFeedViewModelTests: XCTestCase {
    private let messages = WhatsNewCatalog.mock.messages

    func testItemsAreMostRecentlyPublishedFirst() {
        let viewModel = WhatsNewFeedViewModel(messages: messages.shuffled())

        XCTAssertEqual(viewModel.items.map(\.publishedAt), messages.map(\.publishedAt).sorted(by: >))
    }

    /// The detail screen needs the whole message, not just what the row happened to show.
    func testSelectingARowHandsOverItsMessage() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages)
        var selected: WhatsNewMessage?
        viewModel.onSelect = { selected = $0 }

        let item = try XCTUnwrap(viewModel.items.last)
        viewModel.select(item)

        XCTAssertEqual(selected?.id, item.id)
    }

    /// Opening the detail is what marks a message read.
    func testSelectingARowMarksItRead() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages)

        let item = try XCTUnwrap(viewModel.items.first)
        XCTAssertTrue(item.isUnread)

        viewModel.select(item)

        XCTAssertEqual(viewModel.items.first?.isUnread, false)
    }

    func testReadMessagesStartRead() {
        let viewModel = WhatsNewFeedViewModel(messages: messages, readMessageIDs: Set(messages.map(\.id)))

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// Everything on a message's only page can be dropped — an action the allowlist won't open is
    /// the app's own doing — which would leave a row that opens onto nothing.
    func testMessagesWithNothingToShowNeverReachTheFeed() throws {
        let messages = try decodedMessages(json: """
        {
          "schemaVersion": 1,
          "messages": [
            {
              "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
              "type": "tip",
              "publishedAt": "2026-08-17T08:00:00Z",
              "targeting": { "audiences": [] },
              "summary": { "title": "Sort your Up Next" },
              "content": { "pages": [{ "blocks": [{ "type": "paragraph", "content": "…" }] }] }
            },
            {
              "id": "01K2Y3D5J1H7QZP0B6RXKA4N3T",
              "type": "tip",
              "publishedAt": "2026-08-18T08:00:00Z",
              "targeting": { "audiences": [] },
              "summary": { "title": "Rate us" },
              "content": {
                "pages": [
                  { "blocks": [{ "type": "action", "label": "Rate us", "url": "itms-apps://apps.apple.com/app/id414834813" }] }
                ]
              }
            }
          ]
        }
        """)

        let viewModel = WhatsNewFeedViewModel(messages: messages)

        XCTAssertEqual(viewModel.items.map(\.title), ["Sort your Up Next"])
    }

    func testReadingEverythingClearsEveryIndicator() {
        let viewModel = WhatsNewFeedViewModel(messages: messages)
        XCTAssertTrue(viewModel.hasUnreadItems)

        viewModel.markAllAsRead()

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// The Profile row hands over an empty feed, so nothing shows until the catalog arrives.
    func testLoadingFillsTheFeedFromTheCatalog() async {
        let viewModel = WhatsNewFeedViewModel(catalogTask: catalogTask(publishing: Self.catalogJSON))
        XCTAssertTrue(viewModel.items.isEmpty)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.map(\.title), ["Sort your Up Next"])
    }

    /// Reads live in memory until read-state sync lands, so a refresh must not undo them.
    func testReloadingTheCatalogKeepsWhatWasRead() async throws {
        let viewModel = WhatsNewFeedViewModel(catalogTask: catalogTask(publishing: Self.catalogJSON))
        await viewModel.load()
        viewModel.select(try XCTUnwrap(viewModel.items.first))

        await viewModel.load()

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// A feed built from messages the caller already has never goes to the network.
    func testLoadingAFeedBuiltFromMessagesLeavesItAlone() async {
        let viewModel = WhatsNewFeedViewModel(messages: messages)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.count, messages.count)
    }

    // MARK: - Helpers

    override func tearDown() {
        StubURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func decodedMessages(json: String) throws -> [WhatsNewMessage] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(WhatsNewCatalog.self, from: Data(json.utf8)).messages
    }

    private func catalogTask(publishing json: String) -> WhatsNewCatalogTask {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]

        let directory = URL.temporaryDirectory.appending(path: "whats-new-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        return WhatsNewCatalogTask(session: URLSession(configuration: configuration),
                                   cache: WhatsNewCatalogCache(directory: directory))
    }

    private static let catalogJSON = """
    {
      "schemaVersion": 1,
      "messages": [
        {
          "id": "01K2Y08DAWG9N7XJZX5QTH9Z0K",
          "type": "tip",
          "publishedAt": "2026-08-17T08:00:00Z",
          "targeting": { "audiences": [] },
          "summary": { "title": "Sort your Up Next" },
          "content": { "pages": [{ "blocks": [{ "type": "paragraph", "content": "…" }] }] }
        }
      ]
    }
    """
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
