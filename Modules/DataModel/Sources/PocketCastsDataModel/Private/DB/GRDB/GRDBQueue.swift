import GRDB
import Foundation

class GRDBQueue: PCDBQueue {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        withoutActuallyEscaping(block) { block in
            try! dbPool.write { db in
                let dbWrapper = GRDBDatabase(database: db)
                block(dbWrapper)
            }
        }
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        withoutActuallyEscaping(block) { block in
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

    func close() {
        try! dbPool.close()
    }
}
