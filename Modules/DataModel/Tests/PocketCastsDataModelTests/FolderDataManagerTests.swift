import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for FolderDataManager using the public API.
/// These tests run with both SQL and GRDB implementations.
final class FolderDataManagerTests: DataManagerTestCase {

    // MARK: - findFolder Tests

    func testFindFolderReturnsFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "test-folder-uuid", name: "Test Folder", dataManager: dataManager)

            let found = dataManager.findFolder(uuid: "test-folder-uuid")

            XCTAssertNotNil(found, "\(impl): Should find folder")
            XCTAssertEqual(found?.uuid, folder.uuid, "\(impl): UUID should match")
            XCTAssertEqual(found?.name, folder.name, "\(impl): Name should match")
        }
    }

    func testFindFolderReturnsNilForNonExistent() throws {
        try runWithBothImplementations { dataManager, impl in
            let found = dataManager.findFolder(uuid: "non-existent-uuid")

            XCTAssertNil(found, "\(impl): Should not find non-existent folder")
        }
    }

    // MARK: - allFolders Tests

    func testAllFoldersReturnsAllFolders() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Folder 1", dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 2", dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 3", dataManager: dataManager)

            let folders = dataManager.allFolders(includeDeleted: false)

            XCTAssertEqual(folders.count, 3, "\(impl): Should return all 3 folders")
        }
    }

    func testAllFoldersExcludesDeletedByDefault() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Active", wasDeleted: false, dataManager: dataManager)
            _ = self.createTestFolder(name: "Deleted", wasDeleted: true, dataManager: dataManager)

            let folders = dataManager.allFolders(includeDeleted: false)

            XCTAssertEqual(folders.count, 1, "\(impl): Should exclude deleted folder")
            XCTAssertEqual(folders.first?.name, "Active", "\(impl): Should return active folder")
        }
    }

    func testAllFoldersIncludesDeletedWhenRequested() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Active", wasDeleted: false, dataManager: dataManager)
            _ = self.createTestFolder(name: "Deleted", wasDeleted: true, dataManager: dataManager)

            let folders = dataManager.allFolders(includeDeleted: true)

            XCTAssertEqual(folders.count, 2, "\(impl): Should include deleted folder")
        }
    }

    // MARK: - delete Tests

    func testDeleteFolderRemovesFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "to-delete", name: "To Delete", dataManager: dataManager)

            dataManager.delete(folderUuid: folder.uuid, markAsDeleted: false)

            let found = dataManager.findFolder(uuid: folder.uuid)
            XCTAssertNil(found, "\(impl): Should delete folder")
        }
    }

    func testDeleteFolderMarkAsDeletedKeepsFolder() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(uuid: "to-mark-deleted", name: "To Mark Deleted", dataManager: dataManager)

            dataManager.delete(folderUuid: folder.uuid, markAsDeleted: true)

            // Folder should still exist but be marked as deleted
            let found = dataManager.allFolders(includeDeleted: true).first { $0.uuid == folder.uuid }
            XCTAssertNotNil(found, "\(impl): Folder should still exist")
            XCTAssertTrue(found?.wasDeleted == true, "\(impl): Folder should be marked as deleted")
        }
    }

    // MARK: - updateFolderColor Tests

    func testUpdateFolderColorUpdatesColor() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(color: 1, dataManager: dataManager)

            dataManager.updateFolderColor(folderUuid: folder.uuid, color: 5, syncModified: 12345)

            let found = dataManager.findFolder(uuid: folder.uuid)
            XCTAssertEqual(found?.color, 5, "\(impl): Color should be updated")
            XCTAssertEqual(found?.syncModified, 12345, "\(impl): syncModified should be updated")
        }
    }

    func testUpdateFolderColorDoesNothingForNonExistent() throws {
        try runWithBothImplementations { dataManager, impl in
            // Should not throw or crash
            dataManager.updateFolderColor(folderUuid: "non-existent", color: 5, syncModified: 12345)

            XCTAssertTrue(true, "\(impl): Should not crash")
        }
    }

    // MARK: - updateFolderSyncModified Tests

    func testUpdateFolderSyncModifiedUpdatesSyncModified() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(syncModified: 0, dataManager: dataManager)

            dataManager.updateFolderSyncModified(folderUuid: folder.uuid, syncModified: 99999)

            let found = dataManager.findFolder(uuid: folder.uuid)
            XCTAssertEqual(found?.syncModified, 99999, "\(impl): syncModified should be updated")
        }
    }

    // MARK: - bulkSetSyncModified Tests

    func testBulkSetSyncModifiedUpdatesMultipleFolders() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder1 = self.createTestFolder(name: "Folder 1", syncModified: 0, dataManager: dataManager)
            let folder2 = self.createTestFolder(name: "Folder 2", syncModified: 0, dataManager: dataManager)
            let folder3 = self.createTestFolder(name: "Folder 3", syncModified: 0, dataManager: dataManager)

            dataManager.bulkSetSyncModified(54321, onFolders: [folder1.uuid, folder2.uuid])

            let updated1 = dataManager.findFolder(uuid: folder1.uuid)
            let updated2 = dataManager.findFolder(uuid: folder2.uuid)
            let unchanged = dataManager.findFolder(uuid: folder3.uuid)

            XCTAssertEqual(updated1?.syncModified, 54321, "\(impl): Folder 1 syncModified should be updated")
            XCTAssertEqual(updated2?.syncModified, 54321, "\(impl): Folder 2 syncModified should be updated")
            XCTAssertEqual(unchanged?.syncModified, 0, "\(impl): Folder 3 syncModified should be unchanged")
        }
    }

    func testBulkSetSyncModifiedWithEmptyArrayDoesNothing() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(syncModified: 100, dataManager: dataManager)

            dataManager.bulkSetSyncModified(999, onFolders: [])

            let unchanged = dataManager.findFolder(uuid: folder.uuid)
            XCTAssertEqual(unchanged?.syncModified, 100, "\(impl): syncModified should be unchanged")
        }
    }

    // MARK: - markAllFoldersSynced Tests

    func testMarkAllFoldersSyncedSetsAllToZero() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Folder 1", syncModified: 100, dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 2", syncModified: 200, dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 3", syncModified: 300, dataManager: dataManager)

            dataManager.markAllFoldersSynced()

            let folders = dataManager.allFolders(includeDeleted: true)
            XCTAssertTrue(folders.allSatisfy { $0.syncModified == 0 }, "\(impl): All folders should have syncModified = 0")
        }
    }

    // MARK: - allUnsyncedFolders Tests

    func testAllUnsyncedFoldersReturnsUnsyncedFolders() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Unsynced 1", syncModified: 100, dataManager: dataManager)
            _ = self.createTestFolder(name: "Unsynced 2", syncModified: 200, dataManager: dataManager)
            _ = self.createTestFolder(name: "Synced", syncModified: 0, dataManager: dataManager)

            let unsynced = dataManager.allUnsyncedFolders()

            XCTAssertEqual(unsynced.count, 2, "\(impl): Should return 2 unsynced folders")
            XCTAssertTrue(unsynced.allSatisfy { $0.syncModified != 0 }, "\(impl): All should have non-zero syncModified")
        }
    }

    // MARK: - saveSortOrders Tests

    func testSaveSortOrdersUpdatesSortOrders() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder1 = self.createTestFolder(name: "Folder 1", sortOrder: 1, dataManager: dataManager)
            let folder2 = self.createTestFolder(name: "Folder 2", sortOrder: 2, dataManager: dataManager)
            let folder3 = self.createTestFolder(name: "Folder 3", sortOrder: 3, dataManager: dataManager)

            // Update sort orders
            folder1.sortOrder = 3
            folder2.sortOrder = 1
            folder3.sortOrder = 2

            dataManager.saveSortOrders(folders: [folder1, folder2, folder3], syncModified: 33333)

            let updated1 = dataManager.findFolder(uuid: folder1.uuid)
            let updated2 = dataManager.findFolder(uuid: folder2.uuid)
            let updated3 = dataManager.findFolder(uuid: folder3.uuid)

            XCTAssertEqual(updated1?.sortOrder, 3, "\(impl): Folder 1 sortOrder should be 3")
            XCTAssertEqual(updated2?.sortOrder, 1, "\(impl): Folder 2 sortOrder should be 1")
            XCTAssertEqual(updated3?.sortOrder, 2, "\(impl): Folder 3 sortOrder should be 2")
            XCTAssertEqual(updated1?.syncModified, 33333, "\(impl): syncModified should be updated")
        }
    }

    func testSaveSortOrdersWithEmptyArrayDoesNothing() throws {
        try runWithBothImplementations { dataManager, impl in
            let folder = self.createTestFolder(sortOrder: 5, syncModified: 0, dataManager: dataManager)

            dataManager.saveSortOrders(folders: [], syncModified: 12345)

            let unchanged = dataManager.findFolder(uuid: folder.uuid)
            XCTAssertEqual(unchanged?.sortOrder, 5, "\(impl): sortOrder should be unchanged")
            XCTAssertEqual(unchanged?.syncModified, 0, "\(impl): syncModified should be unchanged")
        }
    }

    // MARK: - clearAllFolderInformation Tests

    func testClearAllFolderInformationRemovesAllFolders() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Folder 1", dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 2", dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 3", dataManager: dataManager)

            dataManager.clearAllFolderInformation()

            let folders = dataManager.allFolders(includeDeleted: true)
            XCTAssertEqual(folders.count, 0, "\(impl): Should remove all folders")
        }
    }

    func testClearAllFolderInformationOnEmptyTableDoesNotCrash() throws {
        try runWithBothImplementations { dataManager, impl in
            dataManager.clearAllFolderInformation()

            let folders = dataManager.allFolders(includeDeleted: true)
            XCTAssertEqual(folders.count, 0, "\(impl): Should not crash on empty table")
        }
    }

    // MARK: - deleteAllFoldersAndMarkSync Tests

    func testDeleteAllFoldersAndMarkSyncMarksAllAsDeleted() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestFolder(name: "Folder 1", wasDeleted: false, dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 2", wasDeleted: false, dataManager: dataManager)
            _ = self.createTestFolder(name: "Folder 3", wasDeleted: false, dataManager: dataManager)

            dataManager.deleteAllFoldersAndMarkSync()

            let folders = dataManager.allFolders(includeDeleted: true)
            XCTAssertTrue(folders.allSatisfy { $0.wasDeleted == true }, "\(impl): All folders should be marked as deleted")
        }
    }

    // MARK: - Helper Methods

    private func createTestFolder(
        uuid: String = UUID().uuidString,
        name: String = "Test Folder",
        color: Int32 = 0,
        sortOrder: Int32 = 0,
        sortType: Int32 = 1,
        wasDeleted: Bool = false,
        syncModified: Int64 = 0,
        dataManager: DataManager
    ) -> Folder {
        let folder = Folder()
        folder.uuid = uuid
        folder.name = name
        folder.color = color
        folder.addedDate = Date()
        folder.sortOrder = sortOrder
        folder.sortType = sortType
        folder.wasDeleted = wasDeleted
        folder.syncModified = syncModified
        dataManager.save(folder: folder)
        return folder
    }
}
