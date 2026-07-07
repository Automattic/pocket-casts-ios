@testable import PocketCastsDataModel
import GRDB
import XCTest

/// Regression tests for `GRDBResultSet.next()`.
///
/// `next()` used to swallow cursor errors with `try?` without resetting the
/// cached row. When `RowCursor.next()` threw mid-iteration (e.g. SQLITE_BUSY /
/// SQLITE_IOERR) the previously fetched row stayed in place, so `next()` kept
/// returning `true` and `while resultSet.next()` callers re-processed the last
/// row forever.
final class GRDBResultSetTests: XCTestCase {

    private enum CursorError: Error {
        case simulatedMidIterationFailure
    }

    /// Builds a result set over three rows whose underlying cursor throws while
    /// stepping onto the second row, mimicking a transient SQLite failure.
    ///
    /// The `body` runs inside the database access block because a `RowCursor`
    /// may only be consumed on the connection that created it.
    private func withFailingResultSet(_ body: (GRDBResultSet) throws -> Void) throws {
        let dbQueue = try DatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute(sql: "CREATE TABLE items (value INTEGER)")
            try db.execute(sql: "INSERT INTO items (value) VALUES (1), (2), (3)")

            // Custom SQL function that throws the moment it evaluates the second
            // row, which surfaces as a thrown error from `RowCursor.next()`.
            let explode = DatabaseFunction("explodeOnTwo", argumentCount: 1, pure: true) { values in
                if Int.fromDatabaseValue(values[0]) == 2 {
                    throw CursorError.simulatedMidIterationFailure
                }
                return values[0]
            }
            db.add(function: explode)

            // No ORDER BY: a sequential table scan returns rows in rowid
            // (insertion) order and evaluates `explodeOnTwo` lazily per step, so
            // row 1 is emitted before the function throws while stepping onto
            // row 2. An ORDER BY on the computed column would instead force a
            // full up-front sort pass and throw before the first row.
            let cursor = try Row.fetchCursor(db, sql: "SELECT explodeOnTwo(value) AS value FROM items")
            try body(GRDBResultSet(rowCursor: cursor))
        }
    }

    /// A cursor error must terminate the result set instead of leaving the last
    /// row in place.
    func testNextReturnsFalseWhenCursorThrowsMidIteration() throws {
        try withFailingResultSet { resultSet in
            // First row is fetched normally.
            XCTAssertTrue(resultSet.next())
            XCTAssertEqual(resultSet.int(forColumn: "value"), 1)

            // The next step throws inside the cursor; `next()` must report the
            // end of the result set rather than returning the stale first row.
            XCTAssertFalse(resultSet.next(), "next() should return false when the cursor throws")

            // And it must stay false so callers don't loop back onto the row.
            XCTAssertFalse(resultSet.next())
        }
    }

    /// A `while resultSet.next()` loop over a throwing cursor must terminate.
    func testWhileLoopTerminatesWhenCursorThrows() throws {
        try withFailingResultSet { resultSet in
            var iterations = 0
            while resultSet.next() {
                iterations += 1
                // Safety valve: with the bug this loop never ends.
                if iterations > 100 {
                    break
                }
            }

            XCTAssertEqual(iterations, 1, "loop should process only the single row emitted before the cursor threw")
        }
    }

    /// Sanity check that a healthy cursor still iterates and then terminates.
    func testNextReturnsFalseAfterAllRowsConsumed() throws {
        let dbQueue = try DatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.execute(sql: "CREATE TABLE items (value INTEGER)")
            try db.execute(sql: "INSERT INTO items (value) VALUES (10), (20)")

            let cursor = try Row.fetchCursor(db, sql: "SELECT value FROM items ORDER BY value")
            let resultSet = GRDBResultSet(rowCursor: cursor)

            XCTAssertTrue(resultSet.next())
            XCTAssertEqual(resultSet.int(forColumn: "value"), 10)
            XCTAssertTrue(resultSet.next())
            XCTAssertEqual(resultSet.int(forColumn: "value"), 20)
            XCTAssertFalse(resultSet.next())
            XCTAssertFalse(resultSet.next())
        }
    }
}
