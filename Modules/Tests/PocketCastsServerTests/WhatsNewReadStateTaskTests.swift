import Foundation
@testable import PocketCastsServer
import XCTest

final class WhatsNewReadStateTaskTests: XCTestCase {
    private let messageID = "01K2Y08DAWG9N7XJZX5QTH9Z0K"
    private let otherMessageID = "01K2Y3D5J1H7QZP0B6RXKA4N3T"

    private var account: SignedOutAccount!

    override func setUp() {
        super.setUp()
        account = SignedOutAccount()
    }

    override func tearDown() {
        account.restore()
        super.tearDown()
    }

    func testListsOnlyTheMessagesTheAccountHasRead() async throws {
        let stub = WhatsNewReadStateStub()
        stub.readMessageIDs = [messageID]

        let read = try await stub.task.readMessageIDs(among: [messageID, otherMessageID])

        XCTAssertEqual(read, [messageID])
        XCTAssertEqual(stub.listedMessageIDs, [[messageID, otherMessageID]])
    }

    func testMarksMessagesRead() async throws {
        let stub = WhatsNewReadStateStub()

        try await stub.task.markAsRead([messageID, otherMessageID])

        XCTAssertEqual(stub.markedAsRead, [[messageID, otherMessageID]])
        XCTAssertEqual(stub.readMessageIDs, [messageID, otherMessageID])
    }

    func testMarksMessagesUnread() async throws {
        let stub = WhatsNewReadStateStub()
        stub.readMessageIDs = [messageID, otherMessageID]

        try await stub.task.markAsUnread([messageID])

        XCTAssertEqual(stub.markedAsUnread, [[messageID]])
        XCTAssertEqual(stub.readMessageIDs, [otherMessageID])
    }

    /// The manager keeps what it couldn't push, so a request that didn't land has to say so rather
    /// than read as an account that has nothing.
    func testARequestThatFailsThrows() async {
        let stub = WhatsNewReadStateStub()
        stub.error = URLError(.notConnectedToInternet)

        do {
            _ = try await stub.task.readMessageIDs(among: [messageID])
            XCTFail("A request that never reached the server shouldn't answer with an empty account")
        } catch {}
    }

    func testAnErrorStatusThrows() async {
        let task = WhatsNewReadStateTask(tokenHelper: TokenHelper(urlConnection: URLConnection(mockHandler: { request in
            (nil, HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil))
        })), isSignedIn: { true })

        do {
            try await task.markAsRead([messageID])
            XCTFail("A 500 shouldn't pass for a message the account has stored")
        } catch WhatsNewReadStateTask.WhatsNewReadStateError.requestFailed(let statusCode) {
            XCTAssertEqual(statusCode, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Signed out there's no account to sync with, and the read state stays on the device.
    func testWithoutAnAccountThereIsNothingToSyncWith() {
        let stub = WhatsNewReadStateStub()
        stub.isSignedIn = false

        XCTAssertFalse(stub.task.canSync)
    }
}
