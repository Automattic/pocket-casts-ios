import GRDB
import PocketCastsUtils
import Foundation

public final class GRDBQueue {
    public let dbPool: DatabasePool
    let logger: ErrorLogger?

    public init(dbPool: DatabasePool, logger: ErrorLogger? = nil) {
        self.dbPool = dbPool
        self.logger = logger
    }

    func read(_ block: (any PCDatabase) -> Void) {
        do {
            try dbPool.read { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        } catch {
            logger?.log(error: error, context: [:])
        }
    }

    /// Runs `block` in a transaction. If it throws, the transaction rolls back and
    /// the error is logged.
    func write(fileID: String = #fileID, function: String = #function, _ block: (any PCDatabase) throws -> Void) {
        do {
            try dbPool.write { db in
                let dbWrapper = GRDBDatabase(database: db)
                try block(dbWrapper)
            }
        } catch {
            FileLog.shared.addMessage("\(fileID) \(function) error: \(error)")
            logger?.log(error: error, context: [:])
        }
    }

    /// Runs `VACUUM`, which SQLite rejects inside a transaction, so it can't go through `write`.
    func vacuum() throws {
        try dbPool.vacuum()
    }

    /// The fraction of the database file taken up by free pages that `VACUUM` would reclaim.
    func freePageRatio() throws -> Double {
        try dbPool.read { db in
            let pageCount = try Int.fetchOne(db, sql: "PRAGMA page_count") ?? 0
            let freelistCount = try Int.fetchOne(db, sql: "PRAGMA freelist_count") ?? 0
            return pageCount > 0 ? Double(freelistCount) / Double(pageCount) : 0
        }
    }

    func close() {
        do {
            try dbPool.close()
        } catch {
            logger?.log(error: error, context: [:])
        }
    }
}
