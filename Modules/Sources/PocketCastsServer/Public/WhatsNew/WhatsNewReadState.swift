import Foundation
import PocketCastsUtils

/// What the user has done with the What's New messages, by message ID.
///
/// Outside of a reset no set ever shrinks — nothing marks a message unread again — so two copies of
/// the state combine by keeping everything either one has.
public struct WhatsNewReadState: Codable, Hashable, Sendable {
    /// Messages the user opened or cleared with "Read all".
    public var readMessageIDs: Set<String>

    /// Messages that were in the feed when the user tapped the Profile tab or opened the feed, which
    /// the dot on the tab has already pointed them at.
    public var seenMessageIDs: Set<String>

    /// Messages the feed listed when the user opened it, which the dot on the What's New row has
    /// already pointed them at.
    public var listedMessageIDs: Set<String>

    public init(readMessageIDs: Set<String> = [], seenMessageIDs: Set<String> = [], listedMessageIDs: Set<String> = []) {
        self.readMessageIDs = readMessageIDs
        self.seenMessageIDs = seenMessageIDs
        self.listedMessageIDs = listedMessageIDs
    }

    public func isRead(_ messageID: String) -> Bool {
        readMessageIDs.contains(messageID)
    }

    /// Whether the message is unread and the Profile tab hasn't pointed the user at it yet.
    public func isUnseen(_ messageID: String) -> Bool {
        !isRead(messageID) && !seenMessageIDs.contains(messageID)
    }

    /// Whether the feed has listed the message, read or not.
    public func isListed(_ messageID: String) -> Bool {
        listedMessageIDs.contains(messageID)
    }

    func merging(_ other: WhatsNewReadState) -> WhatsNewReadState {
        WhatsNewReadState(readMessageIDs: readMessageIDs.union(other.readMessageIDs),
                          seenMessageIDs: seenMessageIDs.union(other.seenMessageIDs),
                          listedMessageIDs: listedMessageIDs.union(other.listedMessageIDs))
    }
}

/// Keeps the What's New read state in a file next to the cached catalog.
///
/// Read state is meant to sync across the user's devices through the server; until it does, this
/// file is the only copy.
public struct WhatsNewReadStateStore: Sendable {
    private let fileURL: URL

    public init(directory: URL = WhatsNewCatalogCache.defaultDirectory) {
        fileURL = directory.appending(path: "read-state.json")
    }

    /// The state last saved, or an empty one when nothing has been saved or it can't be read back.
    public func load() -> WhatsNewReadState {
        guard let data = try? Data(contentsOf: fileURL) else { return WhatsNewReadState() }
        do {
            return try JSONDecoder().decode(WhatsNewReadState.self, from: data)
        } catch {
            FileLog.shared.addMessage("What's New: failed to read the read state: \(error.localizedDescription)")
            return WhatsNewReadState()
        }
    }

    public func save(_ state: WhatsNewReadState) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            FileLog.shared.addMessage("What's New: failed to save the read state: \(error.localizedDescription)")
        }
    }
}
