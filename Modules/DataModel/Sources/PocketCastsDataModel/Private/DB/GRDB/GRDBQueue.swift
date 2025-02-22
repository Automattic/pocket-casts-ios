import GRDB
import Foundation

class GRDBQueue: PCDBQueue {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        dbQueue.inDatabase { db in
            let dbWrapper = GRDBDatabase(database: db)
            block(dbWrapper)
        }
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        try! dbQueue.inTransaction { db in
            let rollback = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            rollback.pointee = false
            let dbWrapper = GRDBDatabase(database: db)
            block(dbWrapper, rollback)
            defer { rollback.deallocate() }
            return rollback.pointee.boolValue ? .rollback : .commit
        }
    }

    func close() {
        try! dbQueue.close()
    }
}

