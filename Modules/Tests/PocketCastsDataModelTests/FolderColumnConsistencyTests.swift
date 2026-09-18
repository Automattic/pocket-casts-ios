import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class FolderColumnConsistencyTests: DataManagerTestCase {

    private let columnNames: Set<String> = [
        "uuid",
        "name",
        "color",
        "addedDate",
        "sortOrder",
        "sortType",
        "wasDeleted",
        "syncModified"
    ]

    // MARK: - Database Schema Tests

    func testDatabaseTableHasExpectedColumns() throws {
        let dataManager = DataManager.newTestDataManager()

        // Get actual database columns using GRDB introspection
        guard let grdbQueue = dataManager.dbQueue as? GRDBQueue else {
            XCTFail("Expected GRDBQueue for database introspection")
            return
        }

        let tableColumns = try grdbQueue.dbPool.read { db -> Set<String> in
            let columns = try db.columns(in: DataManager.folderTableName)
            return Set(columns.map { $0.name })
        }

        // The database should have at least all the columns from columnNames
        let missingColumns = columnNames.subtracting(tableColumns)
        XCTAssertTrue(
            missingColumns.isEmpty,
            "Database table is missing columns from columnNames: \(missingColumns)"
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
        }
    }

    // MARK: - Ignored Property Tests

    /// Verifies that cachedUnreadCount is NOT persisted (marked with @GRDBIgnore)
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
