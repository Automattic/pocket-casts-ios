import GRDB
import PocketCastsUtils
import Foundation

class GRDBQueue: PCDBQueue {
    public let dbPool: DatabasePool
    private let logger: ErrorLogger?

    init(dbPool: DatabasePool, logger: ErrorLogger? = nil) {
        self.dbPool = dbPool
        self.logger = logger
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        do {
            try dbPool.write { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        } catch {
            logger?.log(error: error, context: [:])
        }
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        do {
            try dbPool.writeInTransaction { db in
                let rollback = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
                rollback.pointee = false
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper, rollback)
                defer { rollback.deallocate() }
                return rollback.pointee.boolValue ? .rollback : .commit
            }
        } catch {
            logger?.log(error: error, context: [:])
        }
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
