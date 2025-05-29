import Foundation
import PocketCastsUtils
import FMDB

final class FMDBQueue: PCDBQueue {
    private let fmdbQueue: FMDatabaseQueue

    init(fmdbQueue: FMDatabaseQueue) {
        self.fmdbQueue = fmdbQueue
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        if FeatureFlag.fmdbWithoutActuallyEscaping.enabled {
            withoutActuallyEscaping(block) { block in
                fmdbQueue.inDatabase { db in
                    let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                    block(dbWrapper)
                }
            }
        } else {
            fmdbQueue.inDatabase { db in
                let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                block(dbWrapper)
            }
        }
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        if FeatureFlag.fmdbWithoutActuallyEscaping.enabled {
            withoutActuallyEscaping(block) { block in
                fmdbQueue.inTransaction { db, rollback in
                    let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                    block(dbWrapper, rollback)
                }
            }
        } else {
            fmdbQueue.inTransaction { db, rollback in
                let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                block(dbWrapper, rollback)
            }
        }
    }

    func read(_ block: (any PCDatabase) -> Void) {
        // FMDB doesn't have the concept of read or write
        // This is implemented so we conform to the protocol
        if FeatureFlag.fmdbWithoutActuallyEscaping.enabled {
            withoutActuallyEscaping(block) { block in
                fmdbQueue.inDatabase { db in
                    let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                    block(dbWrapper)
                }
            }
        } else {
            withoutActuallyEscaping(block) { block in
                fmdbQueue.inDatabase { db in
                    let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                    block(dbWrapper)
                }
            }
        }
    }

    func write(_ block: (any PCDatabase) -> Void) {
        // FMDB doesn't have the concept of read or write
        // This is implemented so we conform to the protocol
        if FeatureFlag.fmdbWithoutActuallyEscaping.enabled {
            withoutActuallyEscaping(block) { block in
                fmdbQueue.inDatabase { db in
                    let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                    block(dbWrapper)
                }
            }
        } else {
            fmdbQueue.inDatabase { db in
                let dbWrapper = FMDBDatabase(fmdbDatabase: db)
                block(dbWrapper)
            }
        }
    }

    func close() {
        fmdbQueue.close()
    }
}
