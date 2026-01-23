import Foundation
import GRDB

/// GRDB Record type representing the UpNextChanges table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct UpNextChangesRecord: Codable, Identifiable {
    var id: Int64?
    var type: Int32
    var uuid: String?
    var uuids: String?
    var utcTime: Int64

    /// Initializes a default UpNextChangesRecord with reasonable defaults
    init() {
        self.id = nil
        self.type = 0
        self.uuid = nil
        self.uuids = nil
        self.utcTime = 0
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension UpNextChangesRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "UpNextChanges"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension UpNextChangesRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let type = Column(CodingKeys.type)
        static let uuid = Column(CodingKeys.uuid)
        static let uuids = Column(CodingKeys.uuids)
        static let utcTime = Column(CodingKeys.utcTime)
    }
}
