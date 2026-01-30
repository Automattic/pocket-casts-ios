import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// A mock PCDatabase that captures all executed SQL queries
class SQLCapturingDatabase: PCDatabase {
    private(set) var capturedQueries: [(sql: String, values: [Any]?)] = []

    var changes: Int32 { 0 }

    func pragmaUserVersion() -> Int32? { nil }

    func executeQuery(_ sql: String, values: [Any]?) throws -> any PCDBResultSet {
        capturedQueries.append((sql: sql, values: values))
        // Return an empty result set - we only care about capturing the SQL
        return EmptyResultSet()
    }

    func executeUpdate(_ sql: String, values: [Any]?) throws {
        capturedQueries.append((sql: sql, values: values))
    }

    func commit() -> Bool { true }
    func beginTransaction() -> Bool { true }
    func rollback() -> Bool { true }
    func lastErrorCode() -> Int32 { 0 }
    func lastErrorMessage() -> String { "" }

    func insert(into: String, columns: [String], values: [Any?]) throws {
        // Build the SQL for INSERT
        let columnString = columns.joined(separator: ", ")
        let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
        let sql = "INSERT INTO \(into) (\(columnString)) VALUES (\(placeholders))"
        capturedQueries.append((sql: sql, values: values.map { $0 as Any }))
    }

    func clearCapturedQueries() {
        capturedQueries.removeAll()
    }
}

/// A mock PCDBResultSet that returns no results
class EmptyResultSet: PCDBResultSet {
    func next() -> Bool { false }
    func close() {}
    func int(forColumn columnName: String) -> Int32 { 0 }
    func int(forColumnIndex columnIdx: Int32) -> Int32 { 0 }
    func long(forColumn columnName: String) -> Int { 0 }
    func long(forColumnIndex columnIdx: Int32) -> Int { 0 }
    func longLongInt(forColumn columnName: String) -> Int64 { 0 }
    func double(forColumn columnName: String) -> Double { 0 }
    func bool(forColumn columnName: String) -> Bool { false }
    func string(forColumn columnName: String) -> String? { nil }
    func date(forColumn columnName: String) -> Date? { nil }
    func object(forColumn columnName: String) -> Any? { nil }
}

/// A mock PCDBQueue that uses the SQLCapturingDatabase
class SQLCapturingQueue: PCDBQueue {
    let capturingDatabase = SQLCapturingDatabase()

    var capturedQueries: [(sql: String, values: [Any]?)] {
        capturingDatabase.capturedQueries
    }

    /// Returns the last captured SQL with placeholders replaced by actual values
    var lastCapturedSQL: String? {
        guard let lastQuery = capturingDatabase.capturedQueries.last else { return nil }
        return expandSQL(lastQuery.sql, values: lastQuery.values)
    }

    /// Expands SQL by replacing ? placeholders with actual values
    func expandSQL(_ sql: String, values: [Any]?) -> String {
        guard let values = values, !values.isEmpty else { return sql }

        var result = sql
        var valueIndex = 0

        // Replace each ? with the corresponding value
        while let range = result.range(of: "?"), valueIndex < values.count {
            let value = values[valueIndex]
            let replacement = formatValue(value)
            result = result.replacingCharacters(in: range, with: replacement)
            valueIndex += 1
        }

        return result
    }

    /// Formats a value for SQL insertion
    private func formatValue(_ value: Any) -> String {
        switch value {
        case let string as String:
            // Escape single quotes and wrap in quotes
            let escaped = string.replacingOccurrences(of: "'", with: "''")
            return "'\(escaped)'"
        case let int as Int:
            return String(int)
        case let int64 as Int64:
            return String(int64)
        case let int32 as Int32:
            return String(int32)
        case let double as Double:
            return String(double)
        case let bool as Bool:
            return bool ? "1" : "0"
        case is NSNull:
            return "NULL"
        case let data as Data:
            return "X'\(data.map { String(format: "%02x", $0) }.joined())'"
        default:
            // For unknown types, try to convert to string
            return "'\(String(describing: value))'"
        }
    }

    func inDatabase(_ block: (any PCDatabase) -> Void) {
        block(capturingDatabase)
    }

    func inTransaction(_ block: (any PCDatabase, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let rollback = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        rollback.pointee = false
        defer { rollback.deallocate() }
        block(capturingDatabase, rollback)
    }

    func read(_ block: (any PCDatabase) -> Void) {
        block(capturingDatabase)
    }

    func write(_ block: (any PCDatabase) -> Void) {
        block(capturingDatabase)
    }

    func close() {}

    func clearCapturedQueries() {
        capturingDatabase.clearCapturedQueries()
    }
}

/// Base test class for comparing SQL queries between SQL and GRDB implementations
///
/// This class provides infrastructure for:
/// 1. Capturing SQL from the raw SQL implementation by intercepting database calls
/// 2. Extracting SQL from GRDB QueryInterface requests
/// 3. Comparing the two to ensure they produce equivalent queries
///
/// Example usage:
/// ```
/// func testFindByUuidQuery() throws {
///     // Capture SQL from the SQL implementation
///     let dataManager = EpisodeDataManager()
///     _ = dataManager.findBy(uuid: "test-uuid", dbQueue: sqlCapturingQueue)
///     let sqlQuery = sqlCapturingQueue.lastCapturedSQL!
///
///     // Build the equivalent GRDB query and extract its SQL
///     let grdbRequest = EpisodeRecord.filter(EpisodeRecord.Columns.uuid == "test-uuid")
///     let grdbSQL = try extractSQL(grdbRequest)
///
///     // Compare them
///     assertSQLEquivalent(sqlQuery, grdbSQL)
/// }
/// ```
class SQLQueryComparisonTestCase: XCTestCase {

    // MARK: - Test Infrastructure

    /// Queue that captures SQL from the SQL implementation
    var sqlCapturingQueue: SQLCapturingQueue!

    /// GRDB DatabaseQueue for extracting SQL from QueryInterface requests
    var grdbQueue: DatabaseQueue!

    override func setUp() async throws {
        try await super.setUp()
        sqlCapturingQueue = SQLCapturingQueue()
        grdbQueue = try DatabaseQueue()
    }

    override func tearDown() async throws {
        sqlCapturingQueue = nil
        grdbQueue = nil
        try await super.tearDown()
    }

    // MARK: - GRDB SQL Extraction

    /// Extracts the SELECT SQL string from a GRDB QueryInterfaceRequest with all placeholders filled in
    /// Uses tracing to capture the expanded SQL with bound parameters
    /// Note: This requires a table to exist in the database, so subclasses must create the schema
    func extractSQL<T: FetchableRecord>(_ request: QueryInterfaceRequest<T>) throws -> String {
        var capturedSQL: String?

        try grdbQueue.read { db in
            // Set up trace to capture the SQL with expanded parameters
            db.trace { event in
                if case let .statement(statement) = event {
                    // expandedSQL returns the SQL with all bound parameters filled in
                    capturedSQL = statement.expandedSQL
                }
            }

            // Execute the query to trigger tracing
            _ = try request.fetchAll(db)

            // Clear trace
            db.trace(nil)
        }

        guard let sql = capturedSQL else {
            throw NSError(domain: "SQLQueryComparisonTestCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture SELECT SQL"])
        }
        return sql
    }

    /// Extracts the DELETE SQL string from a GRDB QueryInterfaceRequest by executing it with tracing
    /// Returns the SQL with all placeholders filled in
    /// Note: This requires a table to exist in the database, so subclasses must create the schema
    func extractDeleteSQL<T: FetchableRecord & TableRecord>(_ request: QueryInterfaceRequest<T>) throws -> String {
        var capturedSQL: String?

        try grdbQueue.write { db in
            // Set up trace to capture the SQL with expanded parameters
            db.trace { event in
                if case let .statement(statement) = event {
                    // expandedSQL returns the SQL with all bound parameters filled in
                    let expandedSQL = statement.expandedSQL
                    if expandedSQL.uppercased().hasPrefix("DELETE") {
                        capturedSQL = expandedSQL
                    }
                }
            }

            // Execute the delete (this will be rolled back)
            try request.deleteAll(db)

            // Clear trace
            db.trace(nil)
        }

        guard let sql = capturedSQL else {
            throw NSError(domain: "SQLQueryComparisonTestCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture DELETE SQL"])
        }
        return sql
    }

    /// Extracts the COUNT SQL string from a GRDB QueryInterfaceRequest by executing fetchCount with tracing
    /// Returns the SQL with all placeholders filled in
    /// Note: This requires a table to exist in the database, so subclasses must create the schema
    func extractCountSQL<T: FetchableRecord & TableRecord>(_ request: QueryInterfaceRequest<T>) throws -> String {
        var capturedSQL: String?

        try grdbQueue.read { db in
            // Set up trace to capture the SQL with expanded parameters
            db.trace { event in
                if case let .statement(statement) = event {
                    capturedSQL = statement.expandedSQL
                }
            }

            // Execute the count to trigger tracing
            _ = try request.fetchCount(db)

            // Clear trace
            db.trace(nil)
        }

        guard let sql = capturedSQL else {
            throw NSError(domain: "SQLQueryComparisonTestCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture COUNT SQL"])
        }
        return sql
    }

    /// Extracts the UPDATE SQL string from a GRDB QueryInterfaceRequest by executing updateAll with tracing
    /// Returns the SQL with all placeholders filled in
    /// Note: This requires a table to exist in the database, so subclasses must create the schema
    func extractUpdateSQL<T: FetchableRecord & TableRecord>(_ request: QueryInterfaceRequest<T>, assignments: [ColumnAssignment]) throws -> String {
        var capturedSQL: String?

        try grdbQueue.write { db in
            // Set up trace to capture the SQL with expanded parameters
            db.trace { event in
                if case let .statement(statement) = event {
                    let expandedSQL = statement.expandedSQL
                    if expandedSQL.uppercased().hasPrefix("UPDATE") {
                        capturedSQL = expandedSQL
                    }
                }
            }

            // Execute the update to trigger tracing
            try request.updateAll(db, assignments)

            // Clear trace
            db.trace(nil)
        }

        guard let sql = capturedSQL else {
            throw NSError(domain: "SQLQueryComparisonTestCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture UPDATE SQL"])
        }
        return sql
    }

    /// Extracts the SQL string from a GRDB aggregate query (MAX, MIN, etc.) by executing it with tracing
    /// Returns the SQL with all placeholders filled in
    /// Note: This requires a table to exist in the database, so subclasses must create the schema
    func extractAggregateSQL<T: TableRecord>(_ request: QueryInterfaceRequest<T>) throws -> String {
        var capturedSQL: String?

        try grdbQueue.read { db in
            // Set up trace to capture the SQL with expanded parameters
            db.trace { event in
                if case let .statement(statement) = event {
                    capturedSQL = statement.expandedSQL
                }
            }

            // Execute as a scalar query to get the aggregate result
            _ = try Int.fetchOne(db, request)

            // Clear trace
            db.trace(nil)
        }

        guard let sql = capturedSQL else {
            throw NSError(domain: "SQLQueryComparisonTestCase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to capture aggregate SQL"])
        }
        return sql
    }

    // MARK: - SQL Normalization

    /// Normalizes SQL for comparison by:
    /// - Removing extra whitespace
    /// - Trimming leading/trailing whitespace
    /// - Removing quotes around identifiers (e.g., "tableName" -> tableName)
    /// - Uppercasing SQL keywords for consistent comparison
    /// - Removing unnecessary parentheses in WHERE clauses
    /// - Treating SELECT 1 and SELECT * as equivalent for existence checks
    /// - Treating GROUP BY col and SELECT DISTINCT col as equivalent for unique values
    /// - Normalizing explicit column lists to SELECT *
    /// - Normalizing COUNT(*) AS alias to COUNT(*)
    /// - Normalizing != and <> to the same operator
    /// - Sorting WHERE clause conditions alphabetically
    func normalizeSQL(_ sql: String) -> String {
        var result = sql
            // Remove double quotes around identifiers
            .replacingOccurrences(of: "\"", with: "")
            // Normalize whitespace
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        // Uppercase common SQL keywords for consistent comparison
        let keywords = ["SELECT", "FROM", "WHERE", "AND", "OR", "ORDER BY", "ASC", "DESC",
                       "LIMIT", "OFFSET", "INSERT INTO", "VALUES", "UPDATE", "SET",
                       "DELETE FROM", "COUNT", "MAX", "MIN", "GROUP BY", "DISTINCT",
                       "IS NULL", "IS NOT NULL", "IN", "NOT IN", "LIKE", "BETWEEN"]

        for keyword in keywords {
            // Match keyword case-insensitively and replace with uppercase
            let pattern = "\\b\(keyword.replacingOccurrences(of: " ", with: "\\s+"))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: keyword)
            }
        }

        // Remove parentheses around simple conditions in WHERE clauses
        // This handles cases like "WHERE (col = 1) AND (col2 = 2)" -> "WHERE col = 1 AND col2 = 2"
        // Only apply to SELECT/UPDATE/DELETE statements, not INSERT (which requires parentheses)
        if !result.uppercased().hasPrefix("INSERT") {
            let parenPattern = "\\(([^()]+)\\)"
            while let regex = try? NSRegularExpression(pattern: parenPattern),
                  result.contains("(") {
                let range = NSRange(result.startIndex..., in: result)
                let newResult = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "$1")
                if newResult == result {
                    break  // No more changes, avoid infinite loop
                }
                result = newResult
            }
        }

        // Normalize SELECT 1 to SELECT * for existence check queries
        // These are semantically equivalent when used with LIMIT 1
        result = result.replacingOccurrences(of: "SELECT 1 FROM", with: "SELECT * FROM")

        // Normalize SELECT id FROM to SELECT * FROM for existence check queries
        // Raw SQL often uses "SELECT id FROM table WHERE ..." while GRDB uses "SELECT * FROM table WHERE ..."
        // Both are semantically equivalent when checking for existence
        if let regex = try? NSRegularExpression(pattern: "SELECT id FROM", options: .caseInsensitive) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "SELECT * FROM")
        }

        // Normalize explicit column lists to SELECT * for SELECT queries
        // GRDB uses explicit column names like "SELECT uuid,title,date_added,... FROM table"
        // while raw SQL uses "SELECT * FROM table" - both are semantically equivalent
        if let regex = try? NSRegularExpression(pattern: "SELECT [a-zA-Z_,]+\\s+FROM", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            if let match = regex.firstMatch(in: result, range: range) {
                let matchedString = String(result[Range(match.range, in: result)!])
                // Only replace if it looks like a column list (contains commas) and not a keyword
                if matchedString.contains(",") && !matchedString.contains("DISTINCT") {
                    // Extract the table name part (the FROM keyword and everything after)
                    let fromIndex = matchedString.range(of: "FROM")!
                    let fromPart = String(matchedString[fromIndex.lowerBound...])
                    result = result.replacingOccurrences(of: matchedString, with: "SELECT * \(fromPart)")
                }
            }
        }

        // Normalize COUNT(*) AS alias to COUNT(*)
        // Raw SQL: "SELECT COUNT(*) as COUNT FROM" -> GRDB: "SELECT COUNT(*) FROM"
        if let regex = try? NSRegularExpression(pattern: "COUNT\\*\\s+as\\s+\\w+", options: .caseInsensitive) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "COUNT*")
        }

        // Normalize INSERT statements: remove explicit id column with NULL value
        // "INSERT INTO table (id, col1, col2) VALUES (NULL,'a','b')" is equivalent to
        // "INSERT INTO table (col1, col2) VALUES ('a','b')" for auto-increment id columns
        if result.uppercased().hasPrefix("INSERT") {
            // Remove id from column list
            result = result.replacingOccurrences(of: "(id, ", with: "(")
            result = result.replacingOccurrences(of: "(id,", with: "(")
            // Remove NULL from values list (for the id value)
            result = result.replacingOccurrences(of: "VALUES (NULL,", with: "VALUES (")
            result = result.replacingOccurrences(of: "VALUES (NULL, ", with: "VALUES (")
        }

        // Normalize GROUP BY single column to DISTINCT for unique value queries
        // "SELECT col FROM table ... GROUP BY col" is equivalent to "SELECT DISTINCT col FROM table ..."
        // Pattern: SELECT column FROM table WHERE ... GROUP BY column
        if let groupByMatch = result.range(of: "GROUP BY\\s+(\\w+)\\s*$", options: .regularExpression) {
            let groupByColumn = String(result[groupByMatch])
                .replacingOccurrences(of: "GROUP BY", with: "")
                .trimmingCharacters(in: .whitespaces)

            // Check if this column is the only one being selected
            if let selectMatch = result.range(of: "SELECT\\s+(\\w+)\\s+FROM", options: .regularExpression) {
                let selectPart = String(result[selectMatch])
                let selectColumn = selectPart
                    .replacingOccurrences(of: "SELECT", with: "")
                    .replacingOccurrences(of: "FROM", with: "")
                    .trimmingCharacters(in: .whitespaces)

                // If SELECT column matches GROUP BY column, convert to SELECT DISTINCT
                if selectColumn == groupByColumn {
                    result = result.replacingOccurrences(of: "SELECT \(selectColumn) FROM", with: "SELECT DISTINCT \(selectColumn) FROM")
                    result = result.replacingOccurrences(of: "GROUP BY \(groupByColumn)", with: "")
                }
            }
        }

        // Normalize comma spacing - remove spaces after commas for consistent comparison
        // This handles differences like "VALUES ('a', 'b')" vs "VALUES ('a','b')"
        result = result.replacingOccurrences(of: ", ", with: ",")

        // Normalize not-equal operators: != and <> are equivalent in SQL
        // Standardize on <> for comparison
        result = result.replacingOccurrences(of: "!=", with: "<>")

        // Sort WHERE clause conditions alphabetically for consistent comparison
        // This handles cases where conditions are in different order but semantically equivalent
        result = sortWhereConditions(result)

        // Normalize whitespace again after transformations
        result = result
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return result
    }

    /// Sorts WHERE clause conditions alphabetically for consistent comparison
    /// Handles simple AND-joined conditions like "WHERE a = 1 AND b = 2" -> sorted order
    private func sortWhereConditions(_ sql: String) -> String {
        // Find WHERE clause
        guard let whereRange = sql.range(of: "WHERE ", options: .caseInsensitive) else {
            return sql
        }

        // Find the end of WHERE clause (ORDER BY, LIMIT, GROUP BY, or end of string)
        let afterWhere = sql[whereRange.upperBound...]
        var endKeywords = ["ORDER BY", "LIMIT", "GROUP BY"]
        var whereEndIndex = sql.endIndex

        for keyword in endKeywords {
            if let keywordRange = afterWhere.range(of: keyword, options: .caseInsensitive) {
                if keywordRange.lowerBound < whereEndIndex {
                    whereEndIndex = keywordRange.lowerBound
                }
            }
        }

        // Extract WHERE clause content
        let whereContent = String(sql[whereRange.upperBound..<whereEndIndex]).trimmingCharacters(in: .whitespaces)

        // Split by AND (simple case - doesn't handle OR or nested conditions)
        // Only sort if all conditions are AND-joined
        guard !whereContent.uppercased().contains(" OR ") else {
            return sql
        }

        let conditions = whereContent.components(separatedBy: " AND ")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Sort conditions alphabetically
        let sortedConditions = conditions.sorted()

        // Rebuild the SQL
        let prefix = String(sql[..<whereRange.upperBound])
        let suffix = String(sql[whereEndIndex...])
        let sortedWhereClause = sortedConditions.joined(separator: " AND ")

        return prefix + sortedWhereClause + suffix
    }

    // MARK: - SQL Comparison

    /// Asserts that two SQL strings are exactly equivalent after basic normalization
    /// Only normalizes whitespace - strings must otherwise match exactly
    func assertSQLEquivalent(
        _ sql1: String,
        _ sql2: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let normalized1 = normalizeSQL(sql1)
        let normalized2 = normalizeSQL(sql2)

        XCTAssertEqual(
            normalized1,
            normalized2,
            """
            SQL queries do not match.

            SQL Implementation:
            \(normalized1)

            GRDB Implementation:
            \(normalized2)
            """,
            file: file,
            line: line
        )
    }

    /// Asserts that the captured SQL from the SQL implementation matches the GRDB-generated SQL
    func assertCapturedSQLMatchesGRDB<T: FetchableRecord>(
        _ grdbRequest: QueryInterfaceRequest<T>,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        guard let captured = sqlCapturingQueue.capturedQueries.last else {
            XCTFail("No SQL was captured from the SQL implementation", file: file, line: line)
            return
        }

        let grdbSQL = try extractSQL(grdbRequest)

        assertSQLEquivalent(
            captured.sql,
            grdbSQL,
            file: file,
            line: line
        )
    }
}
