import Foundation
import GRDB
import GRDBMacros

@GRDBRecord
public class UpNextChanges: Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "UpNextChanges"

    public enum Actions: Int32 {
        case playNow = 1, playNext = 2, playLast = 3, remove = 4, replace = 5
    }

    public var id: Int64?
    public var type: Int32 = 0
    public var uuid: String?
    public var uuids: String?
    public var utcTime: Int64 = 0

    public init() {}

    /// Updates the record's id after it has been inserted in the database.
    public func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
