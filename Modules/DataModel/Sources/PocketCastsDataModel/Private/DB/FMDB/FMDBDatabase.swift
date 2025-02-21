import Foundation
import FMDB

final class FMDBDatabase: PCDatabase {
    private let fmdbDatabase: FMDatabase

    var changes: Int32 {
        fmdbDatabase.changes
    }

    init(fmdbDatabase: FMDatabase) {
        self.fmdbDatabase = fmdbDatabase
    }

    func executeQuery(_ sql: String, values: [Any]?) throws -> any PCDBResultSet {
        try FMDBResultSet(fmdbResultSet: fmdbDatabase.executeQuery(sql, values: values))
    }

    func executeUpdate(_ sql: String, values: [Any]?) throws {
        try fmdbDatabase.executeUpdate(sql, values: values)
    }

    func commit() {
        fmdbDatabase.commit()
    }

    func beginTransaction() {
        fmdbDatabase.beginTransaction()
    }

    func insert(into: String, columns: [String], values: [Any?]) throws {
        try fmdbDatabase.insert(into: into, columns: columns, values: values)
    }

    func lastErrorCode() -> Int32 {
        fmdbDatabase.lastErrorCode()
    }

    func lastErrorMessage() -> String {
        fmdbDatabase.lastErrorMessage()
    }

    func rollback() {
        fmdbDatabase.rollback()
    }
}
