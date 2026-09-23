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
        guard FeatureFlag.concurrentDatabaseReads.enabled else {
            write(block)
            return
        }

        do {
            try dbPool.read { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        } catch {
            logger?.log(error: error, context: [:])
        }
    }

    func write(_ block: (any PCDatabase) -> Void) {
        do {
            try dbPool.write { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        } catch {
            logger?.log(error: error, context: [:])
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
