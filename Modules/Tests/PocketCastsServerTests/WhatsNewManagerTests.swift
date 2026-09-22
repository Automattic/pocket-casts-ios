import Combine
import Foundation
import PocketCastsUtils
@testable import PocketCastsServer
import XCTest

@MainActor
final class WhatsNewManagerTests: XCTestCase {
    private let messageID = "01K2Y08DAWG9N7XJZX5QTH9Z0K"
    private let otherMessageID = "01K2Y3D5J1H7QZP0B6RXKA4N3T"
    private let pollID = "01K2Y2S65F22TQZQJVNAEXQKHT"

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

    /// The file on disk is what the feed works from, so everything marked in one session has to be
    /// there in the next one, account or no account.
    func testReadStateOutlivesTheManager() async {
        let store = temporaryReadStateStore()
        let manager = manager(cache: temporaryCache(), readStateStore: store)
        await manager.refreshIfNeeded().value

        manager.markAsRead([messageID])
        manager.markAsSeen([otherMessageID])
        manager.markAsListed([messageID])
        manager.markAsResponded(toPoll: pollID)

        let relaunched = self.manager(cache: temporaryCache(), readStateStore: store)
        await relaunched.refreshIfNeeded().value

        XCTAssertEqual(relaunched.readState, WhatsNewReadState(readMessageIDs: [messageID],
                                                               seenMessageIDs: [messageID, otherMessageID],
                                                               listedMessageIDs: [messageID],
                                                               respondedPollIDs: [pollID]))
    }

    /// The saved state predates whatever gets added to it next, and failing to read it would start the
    /// user over.
    func testReadStateSavedBeforeASetWasAddedStillLoads() throws {
        let saved = Data("""
        { "readMessageIDs": ["\(messageID)"], "seenMessageIDs": ["\(otherMessageID)"] }
        """.utf8)

        let readState = try JSONDecoder().decode(WhatsNewReadState.self, from: saved)

        XCTAssertEqual(readState, WhatsNewReadState(readMessageIDs: [messageID], seenMessageIDs: [otherMessageID]))
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

    func testResettingForgetsEverythingReadSeenListedOrAnswered() async {
        let store = temporaryReadStateStore()
        let manager = manager(cache: temporaryCache(), readStateStore: store)
        await manager.refreshIfNeeded().value
        manager.markAsRead([messageID])
        manager.markAsSeen([otherMessageID])
        manager.markAsListed([messageID])
        manager.markAsResponded(toPoll: pollID)

        manager.resetReadState()

        XCTAssertEqual(manager.readState, WhatsNewReadState())
        XCTAssertEqual(store.load(), WhatsNewReadState())
    }

    // MARK: - Read state sync

    /// A message read on another device is read here too, and the file on disk keeps it that way.
    func testTakesOnWhatTheUserReadOnAnotherDevice() async {
        let account = account()
        account.readMessageIDs = [messageID]
        let store = temporaryReadStateStore()
        let manager = manager(cache: temporaryCache(), readStateStore: store, account: account)

        await manager.refreshIfNeeded().value
        await manager.syncReadState().value

        XCTAssertEqual(manager.readState.readMessageIDs, [messageID])
        XCTAssertEqual(store.load().readMessageIDs, [messageID])
    }

    func testReadingAMessagePushesItToTheAccount() async {
        let account = account()
        let manager = manager(cache: temporaryCache(), account: account)
        await manager.refreshIfNeeded().value

        manager.markAsRead([messageID])
        await manager.syncReadState().value

        XCTAssertEqual(account.readMessageIDs, [messageID])
    }

    /// The account answers about the messages it's asked about, and this build's catalog is the whole
    /// of that: a message the feed has dropped can't come back through the account.
    func testTakesOnOnlyTheMessagesThisBuildsCatalogHas() async {
        let account = account()
        account.readMessageIDs = [messageID, otherMessageID]
        let manager = manager(cache: temporaryCache(), account: account)

        await manager.refreshIfNeeded().value
        await manager.syncReadState().value

        XCTAssertEqual(manager.readState.readMessageIDs, [messageID])
    }

    /// Offline, or with the account answering an error, what this device has read has to survive to
    /// be pushed by the next sync.
    func testAFailedSyncKeepsWhatThisDeviceRead() async {
        let account = account()
        account.failingStatusCode = ServerConstants.HttpConstants.serverError
        let manager = manager(cache: temporaryCache(), account: account)
        await manager.refreshIfNeeded().value

        manager.markAsRead([messageID])
        await manager.syncReadState().value

        XCTAssertEqual(manager.readState.readMessageIDs, [messageID])
    }

    /// Signed out there's no account to reconcile with, so nothing is pushed and nothing is taken on.
    func testSignedOutTheReadStateStaysOnTheDevice() async {
        let account = signedOutAccount()
        account.readMessageIDs = [otherMessageID]
        let manager = manager(cache: temporaryCache(), account: account)
        await manager.refreshIfNeeded().value

        manager.markAsRead([messageID])
        await manager.syncReadState().value

        XCTAssertEqual(account.readMessageIDs, [otherMessageID])
        XCTAssertEqual(manager.readState.readMessageIDs, [messageID])
    }

    /// What one user read isn't the next user's, so signing out drops it before another account can
    /// be signed into. The dots belong to the device and keep what they've pointed at.
    func testSigningOutForgetsWhatWasReadButNotWhatTheDotsPointedAt() async {
        let store = temporaryReadStateStore()
        let manager = manager(cache: temporaryCache(), readStateStore: store)
        await manager.refreshIfNeeded().value
        manager.markAsRead([messageID])
        manager.markAsListed([messageID])

        await manager.forgetReadMessages().value

        XCTAssertEqual(manager.readState, WhatsNewReadState(seenMessageIDs: [messageID], listedMessageIDs: [messageID]))
        XCTAssertEqual(store.load().readMessageIDs, [])
    }

    // MARK: - Helpers

    private var requestCount: Int { StubURLProtocol.requestCount }

    private func manager(cache: WhatsNewCatalogCache,
                         readStateStore: WhatsNewReadStateStore? = nil,
                         account: WhatsNewReadStateStub? = nil,
                         refreshInterval: TimeInterval = WhatsNewManager.refreshInterval) -> WhatsNewManager {
        StubURLProtocol.requestHandler = { [json] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let account = account ?? signedOutAccount()
        let task = WhatsNewCatalogTask(session: StubURLProtocol.session(), cache: cache)
        return WhatsNewManager(task: task,
                               readStateStore: readStateStore ?? temporaryReadStateStore(),
                               readStateTask: account.task,
                               refreshInterval: refreshInterval)
    }

    /// An account to sync the read state with.
    ///
    /// The keychain is signed out for the length of the test so `TokenHelper` doesn't go off looking
    /// for a token; the stub is what stands in for having an account.
    private func account() -> WhatsNewReadStateStub {
        let email = ServerSettings.syncingEmail()
        ServerSettings.setSyncingEmail(email: nil)
        addTeardownBlock { ServerSettings.setSyncingEmail(email: email) }
        return WhatsNewReadStateStub()
    }

    /// No account, which is what every test that isn't about syncing runs with.
    private func signedOutAccount() -> WhatsNewReadStateStub {
        let account = WhatsNewReadStateStub()
        account.isSignedIn = false
        return account
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
