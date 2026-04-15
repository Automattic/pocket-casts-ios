import GRDB
import Foundation

class GRDBDatabase: PCDatabase {
    private let database: Database

    var changes: Int32 {
        Int32(database.changesCount)
    }

    init(database: Database) {
        self.database = database
    }

    func pragmaUserVersion() -> Int32? {
        try? Int32.fetchOne(database, sql: "PRAGMA user_version")
    }

    func executeQuery(_ sql: String, values: [Any]?) throws -> any PCDBResultSet {
        // We want GRDB to query `Date` the same way FMDB does: using `timeIntervalSince1970`
        // In terms of raw performance changing that on the model layer would be much better.
        // However, that's a large change that we want to avoid.
        let filteredValues = values?.map { ($0 as? Date)?.timeIntervalSince1970 ?? $0 }

        // Invalid arguments will result in a crash in the application
        // TODO: when releasing GRDB discuss if we want to make this optional
        let rowCursor = try Row.fetchCursor(database, sql: sql, arguments: StatementArguments(filteredValues != nil ? filteredValues! : [])!)
        return GRDBResultSet(rowCursor: rowCursor)
    }

    func executeUpdate(_ sql: String, values: [Any]?) throws {
        // We want GRDB to save `Date` the same way FMDB does: using `timeIntervalSince1970`
        // In terms of raw performance changing that on the model layer would be much better.
        // However, that's a large change that we want to avoid.
        let filteredValues = values?.map { ($0 as? Date)?.timeIntervalSince1970 ?? $0 }

        // Invalid arguments will result in a crash in the application
        // TODO: when releasing GRDB discuss if we want to make this optional
        try database.execute(sql: sql, arguments: StatementArguments(filteredValues != nil ? filteredValues! : [])!)
    }

    func commit() -> Bool {
        // Every operation in GRDB uses a write
        // The only usage of commit in our code doesn't need to execute commit
        // in GRDB.
        return true
    }

    func beginTransaction() -> Bool {
        // Every operation in GRDB uses a write which already starts a transaction
        return true
    }

    func insert(into: String, columns: [String], values: [Any?]) throws {
        try database.insert(into: into, columns: columns, values: values)
    }

    func lastErrorCode() -> Int32 {
        database.lastErrorCode.rawValue
    }

    func lastErrorMessage() -> String {
        database.lastErrorMessage ?? ""
    }

    func rollback() -> Bool {
        do {
            try database.rollback()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - GRDB Helpers

extension Database {
    func insert(into table: String, columns: [String], values: [Any?]) throws {
        let query = """
        INSERT INTO \(table) (
            \(columns.columnString)
        )
        \(values.insertBindingValues)
        """

        try execute(sql: query, arguments: StatementArguments(values.databaseValues)!)
    }
}
