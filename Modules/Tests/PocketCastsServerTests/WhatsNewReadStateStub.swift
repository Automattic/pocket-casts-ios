import Foundation
@testable import PocketCastsServer

/// Stands in for the account's What's New read state, answering the three endpoints in process.
///
/// The requests go through a real `WhatsNewReadStateTask`, so what the stub reads back is what would
/// go over the wire.
final class WhatsNewReadStateStub: @unchecked Sendable {
    /// The messages the account has read.
    var readMessageIDs: Set<String> = []

    /// Thrown in place of answering, for exercising a sync that doesn't reach the server.
    var error: Error?

    private(set) var listedMessageIDs: [Set<String>] = []
    private(set) var markedAsRead: [Set<String>] = []
    private(set) var markedAsUnread: [Set<String>] = []

    /// Whether there's an account to sync with, as the manager sees it.
    var isSignedIn = true

    var task: WhatsNewReadStateTask {
        WhatsNewReadStateTask(tokenHelper: TokenHelper(urlConnection: URLConnection(mockHandler: { [self] request in
            if let error { throw error }
            return try answer(request)
        })), isSignedIn: { [self] in isSignedIn })
    }

    private func answer(_ request: URLRequest) throws -> (Data?, URLResponse?) {
        let uuids = Set(try Api_UuidsRequest(serializedBytes: request.httpBody ?? Data()).uuids)

        switch request.url?.path {
        case "/user/whats_new/read_state/list":
            listedMessageIDs.append(uuids)
            var body = Api_UuidListResponse()
            body.uuids = Array(readMessageIDs.intersection(uuids))
            return (try body.serializedData(), response(for: request, statusCode: ServerConstants.HttpConstants.ok))
        case "/user/whats_new/read":
            markedAsRead.append(uuids)
            readMessageIDs.formUnion(uuids)
        case "/user/whats_new/unread":
            markedAsUnread.append(uuids)
            readMessageIDs.subtract(uuids)
        default:
            return (nil, response(for: request, statusCode: ServerConstants.HttpConstants.notFound))
        }

        return (nil, response(for: request, statusCode: 204))
    }

    private func response(for request: URLRequest, statusCode: Int) -> URLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

/// Signs the run out for the length of a test so `TokenHelper` doesn't go looking for a token, and
/// puts back whatever account the simulator's keychain was left holding.
struct SignedOutAccount {
    private let email = ServerSettings.syncingEmail()

    init() {
        ServerSettings.setSyncingEmail(email: nil)
    }

    func restore() {
        ServerSettings.setSyncingEmail(email: email)
    }
}
