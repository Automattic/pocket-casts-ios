import Foundation
import FMDB

final class FMDBQueue: PCDBQueue {
    private let fmdbQueue: FMDatabaseQueue

    init(fmdbQueue: FMDatabaseQueue) {
        self.fmdbQueue = fmdbQueue
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        fmdbQueue.inDatabase { db in
            let dbWrapper = FMDBDatabase(fmdbDatabase: db)
            block(dbWrapper)
        }
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        fmdbQueue.inTransaction { db, rollback in
            let dbWrapper = FMDBDatabase(fmdbDatabase: db)
            block(dbWrapper, rollback)
        }
    }

    func close() {
        fmdbQueue.close()
    }
}
