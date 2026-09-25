import Foundation
@testable import PocketCastsServer

/// Stands in for the account's What's New read state, answering its endpoints in process.
///
/// The requests go through a real `WhatsNewReadStateTask`, so what the stub reads back is what would
/// go over the wire.
final class WhatsNewReadStateStub: @unchecked Sendable {
    /// The messages the account has read.
    var readMessageIDs: Set<String> = []

    /// Whether there's an account to sync with, as the manager sees it.
    var isSignedIn = true

    /// A status code to answer every request with, standing in for the account being unreachable.
    var failingStatusCode: Int?

    var task: WhatsNewReadStateTask {
        WhatsNewReadStateTask(tokenHelper: TokenHelper(urlConnection: URLConnection(mockHandler: { [self] request in
            try answer(request)
        })), isSignedIn: { [self] in isSignedIn })
    }

    private func answer(_ request: URLRequest) throws -> (Data?, URLResponse?) {
        if let failingStatusCode {
            return (nil, response(for: request, statusCode: failingStatusCode))
        }

        let uuids = Set(try Api_UuidsRequest(serializedBytes: request.httpBody ?? Data()).uuids)

        switch request.url?.path {
        case "/user/whats_new/read_state/list":
            var body = Api_UuidListResponse()
            body.uuids = Array(readMessageIDs.intersection(uuids))
            return (try body.serializedData(), response(for: request, statusCode: ServerConstants.HttpConstants.ok))
        case "/user/whats_new/read":
            readMessageIDs.formUnion(uuids)
        case "/user/whats_new/unread":
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
