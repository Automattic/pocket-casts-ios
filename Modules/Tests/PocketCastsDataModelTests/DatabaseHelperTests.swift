import XCTest
import GRDB
@testable import PocketCastsDataModel

final class DatabaseHelperTests: XCTestCase {
    func testFailedMigrationRollsBackEarlierStepsAndKeepsUserVersion() throws {
        let dbPool = try XCTUnwrap(DatabasePool.newTestDatabase())
        // Migration 76 alters Bookmark and succeeds, then 77 alters the missing SJPodcast table and fails.
        try dbPool.write { db in
            try db.execute(sql: "CREATE TABLE Bookmark (id INTEGER PRIMARY KEY);")
            try db.execute(sql: "PRAGMA user_version = 75;")
        }

        DatabaseHelper.setup(queue: GRDBQueue(dbPool: dbPool))

        try dbPool.read { db in
            XCTAssertEqual(try Int.fetchOne(db, sql: "PRAGMA user_version"), 75)
            XCTAssertFalse(try db.columns(in: "Bookmark").contains { $0.name == "passage" })
        }
    }
}
