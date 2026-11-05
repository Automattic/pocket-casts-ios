import XCTest
import GRDB
@testable import PocketCastsDataModel

final class DatabaseHelperTests: XCTestCase {
    private let bookmarkColumnsAddedInVersion76 = [
        "passage",
        "passage_location",
        "passage_modified_date",
        "reference_time",
        "reference_time_modified_date"
    ]

    func testFailedStepKeepsStartingSchemaVersionAndRetriesOnNextSetup() throws {
        let dbPool = try XCTUnwrap(DatabasePool.newTestDatabase())
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let latestSchemaVersion = try userVersion(dbPool)

        try dbPool.writeWithoutTransaction { db in
            for column in bookmarkColumnsAddedInVersion76 {
                try db.execute(sql: "ALTER TABLE Bookmark DROP COLUMN \(column)")
            }
            try db.execute(sql: "PRAGMA user_version = 75")
        }

        DatabaseHelper.setup(queue: queue)

        XCTAssertEqual(try userVersion(dbPool), 75, "a failed step should leave user_version at the starting version")
        XCTAssertFalse(try columns(in: "Bookmark", dbPool).contains("passage"), "the steps that ran before the failed one should be rolled back")

        try dbPool.writeWithoutTransaction { db in
            try db.execute(sql: "ALTER TABLE SJPodcast DROP COLUMN networkListId")
        }

        DatabaseHelper.setup(queue: queue)

        XCTAssertEqual(try userVersion(dbPool), latestSchemaVersion, "the next setup should retry from the starting version")
        XCTAssertTrue(Set(bookmarkColumnsAddedInVersion76).isSubset(of: try columns(in: "Bookmark", dbPool)), "the retry should add the version 76 columns")
        XCTAssertTrue(try columns(in: "SJPodcast", dbPool).contains("networkListId"), "the retry should add the version 77 column")
    }

    private func userVersion(_ dbPool: DatabasePool) throws -> Int {
        try dbPool.read { try Int.fetchOne($0, sql: "PRAGMA user_version") ?? 0 }
    }

    private func columns(in table: String, _ dbPool: DatabasePool) throws -> Set<String> {
        try dbPool.read { Set(try $0.columns(in: table).map(\.name)) }
    }
}
