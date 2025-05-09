import GRDB
import Foundation

class GRDBQueue: PCDBQueue {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        withoutActuallyEscaping(block) { block in
            // This should be a try? to match FMDB behavior
            // However, while we test GRDB internally we would like any error
            // to be thrown helping us to discover issues.
            // TODO: remove once GRDB has been tested.
            try! dbPool.write { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        }
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        withoutActuallyEscaping(block) { block in
            // This should be a try? to match FMDB behavior
            // However, while we test GRDB internally we would like any error
            // to be thrown helping us to discover issues.
            // TODO: remove once GRDB has been tested.
            try! dbPool.writeInTransaction { db in
                let rollback = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
                rollback.pointee = false
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper, rollback)
                defer { rollback.deallocate() }
                return rollback.pointee.boolValue ? .rollback : .commit
            }
        }
    }

    func read(_ block: (any PCDatabase) -> Void) {
        withoutActuallyEscaping(block) { block in
            // This should be a try? to match FMDB behavior
            // However, while we test GRDB internally we would like any error
            // to be thrown helping us to discover issues.
            // TODO: remove once GRDB has been tested.
            try! dbPool.read { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        }
    }

    func write(_ block: (any PCDatabase) -> Void) {
        withoutActuallyEscaping(block) { block in
            // This should be a try? to match FMDB behavior
            // However, while we test GRDB internally we would like any error
            // to be thrown helping us to discover issues.
            // TODO: remove once GRDB has been tested.
            try! dbPool.write { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        }
    }

    func close() {
        // This should be a try? to match FMDB behavior
        // However, while we test GRDB internally we would like any error
        // to be thrown helping us to discover issues.
        // TODO: remove once GRDB has been tested.
        try! dbPool.close()
    }
}
