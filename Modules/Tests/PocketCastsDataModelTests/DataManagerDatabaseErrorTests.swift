import GRDB
import XCTest
@testable import PocketCastsDataModel

final class DataManagerDatabaseErrorTests: XCTestCase {
    private var directory: URL!
    private var path: String!
    private var fallbackPath: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        path = directory.appendingPathComponent("db.sqlite3").path
        fallbackPath = directory.appendingPathComponent("db_fallback.sqlite3").path
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func testMalformedSchemaIsReportedAndDatabaseIsLeftOnDisk() throws {
        try makeDatabaseWithMalformedSchema()
        let contents = try Data(contentsOf: URL(fileURLWithPath: path))

        let (dbPool, databaseError) = try DataManager.openDatabasePool(path: path, fallbackPath: fallbackPath, configuration: Configuration())

        XCTAssertEqual((databaseError as? DatabaseError)?.resultCode, .SQLITE_CORRUPT)
        try assertDatabaseIsUsable(dbPool)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), contents)
    }

    func testFileThatIsNotDatabaseIsReportedAndLeftOnDisk() throws {
        let contents = Data(repeating: 0x42, count: 4096)
        try contents.write(to: URL(fileURLWithPath: path))

        let (dbPool, databaseError) = try DataManager.openDatabasePool(path: path, fallbackPath: fallbackPath, configuration: Configuration())

        XCTAssertEqual((databaseError as? DatabaseError)?.resultCode, .SQLITE_NOTADB)
        try assertDatabaseIsUsable(dbPool)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), contents)
    }

    func testFallbackDatabaseIsUsedWhenTheDatabaseCannotBeOpened() throws {
        try Data(repeating: 0x42, count: 4096).write(to: URL(fileURLWithPath: path))

        let (dbPool, _) = try DataManager.openDatabasePool(path: path, fallbackPath: fallbackPath, configuration: Configuration())

        XCTAssertEqual(dbPool.path, fallbackPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fallbackPath))
    }

    func testHealthyDatabaseIsOpenedAsIs() throws {
        let existingPool = try DatabasePool(path: path)
        try existingPool.write { db in
            try db.execute(sql: "CREATE TABLE item (name TEXT)")
            try db.execute(sql: "INSERT INTO item (name) VALUES ('existing')")
        }
        try existingPool.close()

        let (dbPool, databaseError) = try DataManager.openDatabasePool(path: path, fallbackPath: fallbackPath, configuration: Configuration())

        XCTAssertNil(databaseError)
        XCTAssertEqual(try dbPool.read { try String.fetchAll($0, sql: "SELECT name FROM item") }, ["existing"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: fallbackPath))
    }

    func testDataManagerCanBeSetUpOnFallbackDatabase() throws {
        try makeDatabaseWithMalformedSchema()

        let (dbPool, _) = try DataManager.openDatabasePool(path: path, fallbackPath: fallbackPath, configuration: Configuration())
        let dataManager = DataManager(dbQueue: GRDBQueue(dbPool: dbPool))

        XCTAssertTrue(dataManager.databaseWasCreated)
        XCTAssertTrue(dataManager.allPodcasts(includeUnsubscribed: true).isEmpty)
    }

    // MARK: - Helpers

    /// Rewrites the `sql` of a `sqlite_master` row on disk so it no longer starts with
    /// "CREATE", which SQLite reports as "malformed database schema (0)" when loading the schema.
    private func makeDatabaseWithMalformedSchema() throws {
        let dbQueue = try DatabaseQueue(path: path)
        try dbQueue.write { db in
            try db.execute(sql: #"CREATE TABLE "0" (name TEXT)"#)
        }
        try dbQueue.close()

        let url = URL(fileURLWithPath: path)
        var data = try Data(contentsOf: url)
        let range = try XCTUnwrap(data.range(of: Data(#"CREATE TABLE "0""#.utf8)))
        data[range.lowerBound] = UInt8(ascii: "X")
        try data.write(to: url)
    }

    private func assertDatabaseIsUsable(_ dbPool: DatabasePool, file: StaticString = #filePath, line: UInt = #line) throws {
        try dbPool.write { db in
            try db.execute(sql: "CREATE TABLE item (name TEXT)")
            try db.execute(sql: "INSERT INTO item (name) VALUES ('new')")
        }
        XCTAssertEqual(try dbPool.read { try String.fetchAll($0, sql: "SELECT name FROM item") }, ["new"], file: file, line: line)
    }
}
