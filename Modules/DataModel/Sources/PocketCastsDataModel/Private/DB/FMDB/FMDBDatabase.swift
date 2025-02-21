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
        try fmdbDatabase.executeQuery(sql, values: values)
    }

    func executeUpdate(_ sql: String, values: [Any]?) throws {
        try fmdbDatabase.executeUpdate(sql, values: values)
    }

    @discardableResult
    func commit() -> Bool {
        fmdbDatabase.commit()
    }

    @discardableResult
    func beginTransaction() -> Bool {
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

    @discardableResult
    func rollback() -> Bool {
        fmdbDatabase.rollback()
    }
}
