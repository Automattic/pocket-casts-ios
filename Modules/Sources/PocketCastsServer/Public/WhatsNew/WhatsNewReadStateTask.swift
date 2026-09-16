import Foundation
import PocketCastsUtils

/// Syncs which What's New messages the user has read with their account, so a message read on one
/// device is read on the rest of them.
///
/// The server keeps a read flag per message and nothing else, and answers about the messages it's
/// asked about rather than about everything it holds: the catalog this build decoded is what the
/// read state is reconciled against, so a message the feed has dropped can't come back through it.
public struct WhatsNewReadStateTask {
    public enum WhatsNewReadStateError: Error {
        case requestFailed(statusCode: Int)
    }

    private let tokenHelper: TokenHelper
    private let isSignedIn: () -> Bool

    public init() {
        self.init(tokenHelper: .shared)
    }

    init(tokenHelper: TokenHelper, isSignedIn: @escaping () -> Bool = { SyncManager.isUserLoggedIn() }) {
        self.tokenHelper = tokenHelper
        self.isSignedIn = isSignedIn
    }

    /// Whether there's an account to sync with. Signed out, the read state stays on the device.
    public var canSync: Bool {
        isSignedIn()
    }

    /// Which of the given messages the account has already read.
    public func readMessageIDs(among messageIDs: some Collection<String>) async throws -> Set<String> {
        let data = try await send(messageIDs, to: "user/whats_new/read_state/list", method: "POST")
        guard let data, !data.isEmpty else { return [] }
        return try Set(JSONDecoder().decode(UuidList.self, from: data).uuids)
    }

    /// Marks the messages read for the account, clearing them on the user's other devices.
    public func markAsRead(_ messageIDs: some Collection<String>) async throws {
        _ = try await send(messageIDs, to: "user/whats_new/read", method: "PUT")
    }

    /// Marks the messages unread for the account, bringing them back on the user's other devices.
    public func markAsUnread(_ messageIDs: some Collection<String>) async throws {
        _ = try await send(messageIDs, to: "user/whats_new/unread", method: "PUT")
    }

    private func send(_ messageIDs: some Collection<String>, to path: String, method: String) async throws -> Data? {
        let url = try URL(throwing: ServerConstants.Urls.api() + path)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.seconds)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        request.setValue("application/json", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.addLocalizationHeaders()
        request.httpBody = try JSONEncoder().encode(UuidList(uuids: Array(messageIDs)))

        let (response, data) = try await tokenHelper.callSecureUrl(request: request)

        let statusCode = response?.statusCode ?? ServerConstants.HttpConstants.serverError
        guard 200 ..< 300 ~= statusCode else {
            throw WhatsNewReadStateError.requestFailed(statusCode: statusCode)
        }
        return data
    }

    /// The body every read-state endpoint takes, and the one the list endpoint answers with.
    private struct UuidList: Codable {
        let uuids: [String]
    }
}
