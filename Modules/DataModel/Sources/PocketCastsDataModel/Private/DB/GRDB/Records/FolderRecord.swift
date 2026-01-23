import Foundation
import GRDB

/// GRDB Record type representing the Folder table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct FolderRecord: Codable {
    var uuid: String
    var name: String
    var color: Int32
    var addedDate: Int64
    var sortOrder: Int32
    var sortType: Int32
    var wasDeleted: Bool
    var syncModified: Int64

    /// Initializes a default FolderRecord with reasonable defaults
    init() {
        self.uuid = ""
        self.name = ""
        self.color = 0
        self.addedDate = 0
        self.sortOrder = 0
        self.sortType = 0
        self.wasDeleted = false
        self.syncModified = 0
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension FolderRecord: FetchableRecord, PersistableRecord {
    static let databaseTableName = "Folder"
}

// MARK: - Column Definitions

extension FolderRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let uuid = Column(CodingKeys.uuid)
        static let name = Column(CodingKeys.name)
        static let color = Column(CodingKeys.color)
        static let addedDate = Column(CodingKeys.addedDate)
        static let sortOrder = Column(CodingKeys.sortOrder)
        static let sortType = Column(CodingKeys.sortType)
        static let wasDeleted = Column(CodingKeys.wasDeleted)
        static let syncModified = Column(CodingKeys.syncModified)
    }
}
