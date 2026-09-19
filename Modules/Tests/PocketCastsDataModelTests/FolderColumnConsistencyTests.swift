import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class FolderColumnConsistencyTests: DataManagerTestCase {

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let tableColumns = try DataManager.newTestDataManager().testDbQueue.dbPool.read { db in
            Set(try db.columns(in: DataManager.folderTableName).map(\.name))
        }
        let encodedColumns = Set(try Folder().databaseDictionary.keys)

        XCTAssertEqual(
            encodedColumns.subtracting(tableColumns),
            [],
            "Folder encodes columns the table doesn't have"
        )
        XCTAssertEqual(
            tableColumns.subtracting(encodedColumns),
            [],
            "Table columns that saving a Folder doesn't write"
        )
    }

    // MARK: - Round-Trip Tests

    func testSaveAndLoadPreservesAllFields() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let original = self.createFullyPopulatedFolder()

            // Save using the current implementation (respects feature flag)
            dataManager.save(folder: original)

            // Load it back
            guard let loaded = dataManager.findFolder(uuid: original.uuid) else {
                XCTFail("\(implementationName): Should be able to load saved folder")
                return
            }

            // Verify all persisted fields match
            XCTAssertEqual(loaded.uuid, original.uuid, "\(implementationName): uuid should match")
            XCTAssertEqual(loaded.name, original.name, "\(implementationName): name should match")
            XCTAssertEqual(loaded.color, original.color, "\(implementationName): color should match")
            XCTAssertEqual(loaded.sortOrder, original.sortOrder, "\(implementationName): sortOrder should match")
            XCTAssertEqual(loaded.sortType, original.sortType, "\(implementationName): sortType should match")
            XCTAssertEqual(loaded.wasDeleted, original.wasDeleted, "\(implementationName): wasDeleted should match")
            XCTAssertEqual(loaded.syncModified, original.syncModified, "\(implementationName): syncModified should match")
            XCTAssertEqual(
                loaded.addedDate?.timeIntervalSince1970,
                original.addedDate?.timeIntervalSince1970,
                "\(implementationName): addedDate should match"
            )
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that cachedUnreadCount is NOT persisted
    func testCachedUnreadCountNotPersisted() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let folder = Folder()
            folder.uuid = UUID().uuidString.lowercased()
            folder.name = "Test Folder"
            folder.addedDate = Date()
            folder.cachedUnreadCount = 42  // Set ignored property

            dataManager.save(folder: folder)

            // Load it back - cachedUnreadCount should be default (0)
            guard let loaded = dataManager.findFolder(uuid: folder.uuid) else {
                XCTFail("\(implementationName): Should find saved folder")
                return
            }

            // cachedUnreadCount should be 0 because it's not persisted
            XCTAssertEqual(loaded.cachedUnreadCount, 0, "\(implementationName): cachedUnreadCount should NOT be persisted")
        }
    }

    // MARK: - GRDB Record Tests

    /// addedDate is stored as a Unix timestamp, not GRDB's default Date format.
    /// The legacy read path reads it back with `rs.double(forColumn:)`, so a change
    /// here would silently shift every folder's creation date.
    func testAddedDateIsEncodedAsUnixTimestamp() throws {
        let folder = createFullyPopulatedFolder()
        let encoded = try folder.databaseDictionary

        let addedDate = try XCTUnwrap(encoded["addedDate"])
        XCTAssertEqual(
            Double.fromDatabaseValue(addedDate),
            folder.addedDate?.timeIntervalSince1970,
            "addedDate should encode as a Unix timestamp"
        )
    }

    func testNilAddedDateIsEncodedAsNull() throws {
        let folder = createFullyPopulatedFolder()
        folder.addedDate = nil

        let encoded = try folder.databaseDictionary

        XCTAssertEqual(encoded["addedDate"], .null, "a nil addedDate should encode as NULL")
    }

    func testCachedUnreadCountIsNotEncoded() throws {
        let folder = createFullyPopulatedFolder()
        folder.cachedUnreadCount = 42

        let encoded = try folder.databaseDictionary

        XCTAssertNil(encoded["cachedUnreadCount"], "cachedUnreadCount is transient and should not be encoded")
    }

    func testDecodesRowWrittenByGRDB() throws {
        let dataManager = DataManager.newTestDataManager()
        let original = createFullyPopulatedFolder()
        dataManager.save(folder: original)

        let decoded = try dataManager.testDbQueue.dbPool.read { db in
            try Folder.fetchOne(
                db,
                sql: "SELECT * FROM \(DataManager.folderTableName) WHERE uuid = ?",
                arguments: [original.uuid]
            )
        }

        let folder = try XCTUnwrap(decoded, "should decode a Folder from its own row")
        XCTAssertEqual(folder.uuid, original.uuid)
        XCTAssertEqual(folder.name, original.name)
        XCTAssertEqual(folder.color, original.color)
        XCTAssertEqual(
            folder.addedDate?.timeIntervalSince1970,
            original.addedDate?.timeIntervalSince1970
        )
        XCTAssertEqual(folder.sortOrder, original.sortOrder)
        XCTAssertEqual(folder.sortType, original.sortType)
        XCTAssertEqual(folder.wasDeleted, original.wasDeleted)
        XCTAssertEqual(folder.syncModified, original.syncModified)
    }

    /// Every property decodes with a fallback, so a row missing columns (an older
    /// schema, or a projection) yields defaults instead of throwing.
    func testDecodesRowWithMissingColumnsUsingDefaults() throws {
        let row: Row = ["uuid": "abc"]

        let folder = try Folder(row: row)

        XCTAssertEqual(folder.uuid, "abc")
        XCTAssertEqual(folder.name, "")
        XCTAssertEqual(folder.color, 0)
        XCTAssertNil(folder.addedDate)
        XCTAssertEqual(folder.sortOrder, 0)
        XCTAssertEqual(folder.sortType, 0)
        XCTAssertFalse(folder.wasDeleted)
        XCTAssertEqual(folder.syncModified, 0)
    }

    func testDecodesRowWithNullColumnsUsingDefaults() throws {
        let row: Row = [
            "uuid": nil, "name": nil, "color": nil, "addedDate": nil,
            "sortOrder": nil, "sortType": nil, "wasDeleted": nil, "syncModified": nil
        ]

        let folder = try Folder(row: row)

        XCTAssertEqual(folder.uuid, "")
        XCTAssertEqual(folder.name, "")
        XCTAssertEqual(folder.color, 0)
        XCTAssertNil(folder.addedDate)
        XCTAssertEqual(folder.sortOrder, 0)
        XCTAssertEqual(folder.sortType, 0)
        XCTAssertFalse(folder.wasDeleted)
        XCTAssertEqual(folder.syncModified, 0)
    }

    // MARK: - Helpers

    private func createFullyPopulatedFolder() -> Folder {
        let folder = Folder()
        folder.uuid = UUID().uuidString.lowercased()
        folder.name = "Test Folder"
        folder.color = 3
        folder.addedDate = Date()
        folder.sortOrder = 5
        folder.sortType = FolderSort.titleAtoZ.rawValue
        folder.wasDeleted = false
        folder.syncModified = 123456789
        return folder
    }
}
