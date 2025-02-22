import GRDB

class GRDBDatabase: PCDatabase {
    private let database: Database

    var changes: Int32 {
        Int32(database.changesCount)
    }

    init(database: Database) {
        self.database = database
    }

    func executeQuery(_ sql: String, values: [Any]?) throws -> any PCDBResultSet {
        let rowCursor = try Row.fetchCursor(database, sql: sql, arguments: StatementArguments(values != nil ? values! : [])!)
        return GRDBResultSet(rowCursor: rowCursor)
    }

    func executeUpdate(_ sql: String, values: [Any]?) throws {
        try database.execute(sql: sql, arguments: StatementArguments(values != nil ? values! : [])!)
    }

    func commit() -> Bool {
        // Not needed in GRDB
        try! database.commit()
        return true
    }

    func beginTransaction() -> Bool {
        // Not needed in GRDB
        try! database.beginTransaction(.exclusive)
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

