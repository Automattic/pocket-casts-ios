import PocketCastsServer
import PocketCastsUtils
import XCTest

@testable import podcasts

@MainActor
final class WhatsNewFeedViewModelTests: XCTestCase {
    private let messages = WhatsNewCatalog.mock.messages

    /// The mock messages are targeted, so the tests fix the audience and the build rather than
    /// letting whatever the test host is signed in as decide which of them reach the feed.
    private let targeting = WhatsNewMessageFilter(audience: .free, appVersion: Version("8.10"))

    func testItemsAreMostRecentlyPublishedFirst() {
        let viewModel = WhatsNewFeedViewModel(messages: messages.shuffled(), targeting: targeting)

        XCTAssertEqual(viewModel.items.map(\.publishedAt), messages.map(\.publishedAt).sorted(by: >))
    }

    /// The label and the icon are this app's, picked from the type rather than published with the
    /// message, so they arrive in the reader's language whoever wrote it.
    func testARowIsLabelledByItsType() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)

        let research = try XCTUnwrap(viewModel.items.first { $0.type == .research })
        XCTAssertEqual(research.label, L10n.whatsNewCategoryResearch)
        XCTAssertEqual(research.title, "Help shape the player")
    }

    /// The detail screen needs the whole message, not just what the row happened to show.
    func testSelectingARowHandsOverItsMessage() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)
        var selected: WhatsNewMessage?
        viewModel.onSelect = { selected = $0 }

        let item = try XCTUnwrap(viewModel.items.last)
        viewModel.select(item)

        XCTAssertEqual(selected?.id, item.id)
    }

    /// Opening the detail is what marks a message read.
    func testSelectingARowMarksItRead() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)

        let item = try XCTUnwrap(viewModel.items.first)
        XCTAssertTrue(item.isUnread)

        viewModel.select(item)

        XCTAssertEqual(viewModel.items.first?.isUnread, false)
    }

    func testReadMessagesStartRead() {
        let viewModel = WhatsNewFeedViewModel(messages: messages, readMessageIDs: Set(messages.map(\.id)), targeting: targeting)

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// The catalog is published per platform and locale, so the rest of the targeting is the
    /// client's to apply — including to whether the feed has anything unread.
    func testMessagesThisUserIsNotTargetedByNeverReachTheFeed() throws {
        let messages = try decodedMessages(json: """
        {
          "schemaVersion": 1,
          "messages": [
            \(Self.tip(id: "550e8400-e29b-41d4-a716-446655440001",
                       title: "Sort your Up Next",
                       publishedAt: "2026-08-17T08:00:00Z")),
            {
              "id": "550e8400-e29b-41d4-a716-446655440002",
              "type": "announcement",
              "publishedAt": "2026-08-18T08:00:00Z",
              "targeting": { "audiences": ["patron"] },
              "title": "Thanks for being a Patron",
              "pages": [\(Self.page)]
            },
            {
              "id": "550e8400-e29b-41d4-a716-446655440003",
              "type": "new_feature",
              "publishedAt": "2026-08-19T08:00:00Z",
              "expiresAt": "2026-08-20T08:00:00Z",
              "targeting": { "audiences": [], "minimumAppVersion": "9.0" },
              "title": "Something newer builds have",
              "pages": [\(Self.page)]
            }
          ]
        }
        """)

        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)

        XCTAssertEqual(viewModel.items.map(\.title), ["Sort your Up Next"])
        XCTAssertTrue(viewModel.hasUnreadItems)
    }

    func testReadingEverythingClearsEveryIndicator() {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)
        XCTAssertTrue(viewModel.hasUnreadItems)

        viewModel.markAllAsRead()

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// A poll is answered once, so backing out of a message and opening it again has to find the
    /// answer that was already given.
    func testAPollThatWasAnsweredStaysAnswered() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)
        let message = try XCTUnwrap(messages.first { $0.type == .research })
        let poll = try XCTUnwrap(message.content.research?.poll)

        XCTAssertFalse(viewModel.hasResponded(to: message))
        viewModel.markAsResponded(to: poll)

        XCTAssertTrue(viewModel.hasResponded(to: message))
    }

    func testAMessageWithNoPollWasNeverAnswered() throws {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)
        let message = try XCTUnwrap(messages.first { $0.type == .tip })

        XCTAssertFalse(viewModel.hasResponded(to: message))
    }

    /// The Profile row hands over an empty feed, so nothing shows until the catalog arrives.
    func testLoadingFillsTheFeedFromTheCatalog() async {
        let viewModel = WhatsNewFeedViewModel(manager: manager(publishing: Self.catalogJSON), targeting: targeting)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.state, .loading)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.map(\.title), ["Sort your Up Next"])
        XCTAssertEqual(viewModel.state, .loaded)
    }

    /// With no cached copy to fall back to, a catalog that can't be reached is a failure, not an empty feed.
    func testFailingToReachTheCatalogWithNothingCachedFails() async {
        let viewModel = WhatsNewFeedViewModel(manager: manager())

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testRetryingFillsTheFeedOnceTheCatalogCanBeReached() async {
        let viewModel = WhatsNewFeedViewModel(manager: manager())
        await viewModel.load()
        publish(Self.catalogJSON)

        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.items.map(\.title), ["Sort your Up Next"])
    }

    /// Pulling to refresh doesn't wait for the copy the feed opened on to age out.
    func testRefreshingShowsWhatWasPublishedSinceTheFeedLoaded() async {
        let viewModel = WhatsNewFeedViewModel(manager: manager(publishing: Self.catalogJSON), targeting: targeting)
        await viewModel.load()
        publish("""
        {
          "schemaVersion": 1,
          "messages": [
            \(Self.tip(id: "550e8400-e29b-41d4-a716-446655440001",
                       title: "Sort your Up Next",
                       publishedAt: "2026-08-17T08:00:00Z")),
            {
              "id": "550e8400-e29b-41d4-a716-446655440002",
              "type": "new_feature",
              "publishedAt": "2026-08-18T08:00:00Z",
              "targeting": { "audiences": [] },
              "title": "Folders for everyone",
              "pages": [\(Self.page)]
            }
          ]
        }
        """)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.items.map(\.title), ["Folders for everyone", "Sort your Up Next"])
    }

    /// A refresh publishes the catalog again, which mustn't undo what was read.
    func testReloadingTheCatalogKeepsWhatWasRead() async throws {
        let viewModel = WhatsNewFeedViewModel(manager: manager(publishing: Self.catalogJSON), targeting: targeting)
        await viewModel.load()
        viewModel.select(try XCTUnwrap(viewModel.items.first))

        await viewModel.load()

        XCTAssertFalse(viewModel.hasUnreadItems)
    }

    /// A feed built from messages the caller already has never goes to the network.
    func testLoadingAFeedBuiltFromMessagesLeavesItAlone() async {
        let viewModel = WhatsNewFeedViewModel(messages: messages, targeting: targeting)

        await viewModel.load()

        XCTAssertEqual(viewModel.items.count, messages.count)
    }

    // MARK: - Read state

    /// Reads go through the manager, so the feed opens on them next time and the dots on Profile agree.
    func testSelectingARowMarksItsMessageReadInTheManager() async throws {
        let manager = manager(publishing: Self.catalogJSON)
        let viewModel = WhatsNewFeedViewModel(manager: manager, targeting: targeting)
        await viewModel.load()

        viewModel.select(try XCTUnwrap(viewModel.items.first))

        XCTAssertEqual(manager.readState.readMessageIDs, [Self.tipID])
        XCTAssertFalse(WhatsNewFeedViewModel(manager: manager, targeting: targeting).hasUnreadItems)
    }

    /// "Read all" can only vouch for the messages the user was shown.
    func testReadingEverythingLeavesOutMessagesTheFeedDoesNotShow() async {
        let manager = manager(publishing: Self.catalogWithPatronMessageJSON)
        let viewModel = WhatsNewFeedViewModel(manager: manager, targeting: targeting)
        await viewModel.load()

        viewModel.markAllAsRead()

        XCTAssertEqual(manager.readState.readMessageIDs, [Self.tipID])
    }

    /// The read state can be reset from the developer menu while a feed is open.
    func testResettingTheReadStateBringsBackTheFeedsIndicators() async {
        let manager = manager(publishing: Self.catalogJSON)
        let viewModel = WhatsNewFeedViewModel(manager: manager, targeting: targeting)
        await viewModel.load()
        viewModel.markAllAsRead()

        manager.resetReadState()

        XCTAssertTrue(viewModel.hasUnreadItems)
    }

    /// Profile builds a new feed each time the row is tapped, so an answer has to outlast the feed it
    /// was given in.
    func testAPollAnsweredInAnEarlierFeedStaysAnswered() throws {
        let manager = manager()
        let message = try XCTUnwrap(messages.first { $0.type == .research })
        let poll = try XCTUnwrap(message.content.research?.poll)

        WhatsNewFeedViewModel(manager: manager, targeting: targeting).markAsResponded(to: poll)

        XCTAssertTrue(WhatsNewFeedViewModel(manager: manager, targeting: targeting).hasResponded(to: message))
    }

    // MARK: - Profile indicators

    func testTappingTheProfileTabTakesOnlyItsOwnDotOff() async {
        let manager = manager(publishing: Self.catalogJSON)
        await manager.refreshIfNeeded().value
        XCTAssertTrue(manager.hasUnseenMessages(targeting: targeting))

        manager.markFeedAsSeen(targeting: targeting)

        XCTAssertFalse(manager.hasUnseenMessages(targeting: targeting))
        XCTAssertTrue(manager.hasUnlistedMessages(targeting: targeting))
    }

    /// The dot on the What's New row points at the feed, not at what's unread in it.
    func testOpeningTheFeedTakesBothDotsOffWithoutReadingAnything() async {
        let manager = manager(publishing: Self.catalogJSON)
        await manager.refreshIfNeeded().value
        XCTAssertTrue(manager.hasUnlistedMessages(targeting: targeting))

        let viewModel = WhatsNewFeedViewModel(manager: manager, targeting: targeting)

        XCTAssertFalse(manager.hasUnlistedMessages(targeting: targeting))
        XCTAssertFalse(manager.hasUnseenMessages(targeting: targeting))
        XCTAssertTrue(viewModel.hasUnreadItems)
    }

    func testANewMessagePutsTheDotBackOnTheProfileTab() async {
        let manager = manager(publishing: Self.catalogJSON, refreshInterval: 0)
        await manager.refreshIfNeeded().value
        manager.markFeedAsSeen(targeting: targeting)

        publish(Self.catalogWithNewMessageJSON)
        await manager.refreshIfNeeded().value

        XCTAssertTrue(manager.hasUnseenMessages(targeting: targeting))
    }

    /// The feed can open before the catalog is in, so what it goes on to list counts as well.
    func testANewMessagePutsTheDotBackOnTheWhatsNewRow() async {
        let manager = manager(publishing: Self.catalogJSON, refreshInterval: 0)
        await WhatsNewFeedViewModel(manager: manager, targeting: targeting).load()
        XCTAssertFalse(manager.hasUnlistedMessages(targeting: targeting))

        publish(Self.catalogWithNewMessageJSON)
        await manager.refreshIfNeeded().value

        XCTAssertTrue(manager.hasUnlistedMessages(targeting: targeting))
    }

    /// A dot on Profile has to lead to a row in the feed.
    func testProfileDotsIgnoreMessagesTheFeedDoesNotShow() async {
        let manager = manager(publishing: Self.catalogWithPatronMessageJSON)
        await manager.refreshIfNeeded().value

        manager.markAsListed([Self.tipID])

        XCTAssertFalse(manager.hasUnlistedMessages(targeting: targeting))
        XCTAssertFalse(manager.hasUnseenMessages(targeting: targeting))
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

    /// A manager whose catalog answers with `json`, or fails every request until something is published.
    private func manager(publishing json: String? = nil,
                         refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) -> WhatsNewManager {
        if let json {
            publish(json)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]

        let directory = URL.temporaryDirectory.appending(path: "whats-new-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let task = WhatsNewCatalogTask(session: URLSession(configuration: configuration),
                                       cache: WhatsNewCatalogCache(directory: directory))
        return WhatsNewManager(task: task,
                               readStateStore: WhatsNewReadStateStore(directory: directory),
                               refreshInterval: refreshInterval)
    }

    private func publish(_ json: String) {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }
    }

    private static let tipID = "550e8400-e29b-41d4-a716-446655440001"

    private static let page = """
    {
      "image": { "url": "https://static.pocketcasts.com/a.webp", "width": 1200, "height": 750, "alt": "…" },
      "heading": "Put the queue in the order you want",
      "description": "…"
    }
    """

    private static func tip(id: String, title: String, publishedAt: String) -> String {
        """
        {
          "id": "\(id)",
          "type": "tip",
          "publishedAt": "\(publishedAt)",
          "targeting": { "audiences": [] },
          "title": "\(title)",
          "pages": [\(page)]
        }
        """
    }

    private static let catalogJSON = """
    {
      "schemaVersion": 1,
      "messages": [\(tip(id: tipID,
                         title: "Sort your Up Next",
                         publishedAt: "2026-08-17T08:00:00Z"))]
    }
    """

    /// The tip, and a message a free account isn't shown.
    private static let catalogWithPatronMessageJSON = """
    {
      "schemaVersion": 1,
      "messages": [
        \(tip(id: tipID,
              title: "Sort your Up Next",
              publishedAt: "2026-08-17T08:00:00Z")),
        {
          "id": "550e8400-e29b-41d4-a716-446655440002",
          "type": "announcement",
          "publishedAt": "2026-08-18T08:00:00Z",
          "targeting": { "audiences": ["patron"] },
          "title": "Thanks for being a Patron",
          "pages": [\(page)]
        }
      ]
    }
    """

    /// The tip, and a message published after it.
    private static let catalogWithNewMessageJSON = """
    {
      "schemaVersion": 1,
      "messages": [
        \(tip(id: tipID,
              title: "Sort your Up Next",
              publishedAt: "2026-08-17T08:00:00Z")),
        {
          "id": "550e8400-e29b-41d4-a716-446655440003",
          "type": "new_feature",
          "publishedAt": "2026-08-19T08:00:00Z",
          "targeting": { "audiences": [] },
          "title": "Introducing Playlists",
          "pages": [\(page)]
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
