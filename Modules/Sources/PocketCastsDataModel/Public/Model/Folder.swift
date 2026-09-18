import Foundation
import GRDB

public class Folder: NSObject, Identifiable {
    @objc public var uuid = ""
    @objc public var name = ""
    @objc public var color: Int32 = 0
    @objc public var addedDate: Date?
    @objc public var sortOrder: Int32 = 0
    @objc public var sortType: Int32 = 0
    @objc public var wasDeleted = false
    @objc public var syncModified: Int64 = 0

    // transient not saved to database
    public var cachedUnreadCount = 0

    override public init() {}

    func folderSort() -> FolderSort {
        FolderSort(rawValue: sortType) ?? .dateAddedNewestToOldest
    }

    // MARK: - GRDB

    public static let databaseTableName = "Folder"

    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case color
        case addedDate
        case sortOrder
        case sortType
        case wasDeleted
        case syncModified
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        color = try container.decodeIfPresent(Int32.self, forKey: .color) ?? 0
        addedDate = try container.decodeIfPresent(Date.self, forKey: .addedDate)
        sortOrder = try container.decodeIfPresent(Int32.self, forKey: .sortOrder) ?? 0
        sortType = try container.decodeIfPresent(Int32.self, forKey: .sortType) ?? 0
        wasDeleted = try container.decodeIfPresent(Bool.self, forKey: .wasDeleted) ?? false
        syncModified = try container.decodeIfPresent(Int64.self, forKey: .syncModified) ?? 0
    }

    public func encode(to container: inout PersistenceContainer) {
        container["uuid"] = uuid
        container["name"] = name
        container["color"] = color
        container["addedDate"] = addedDate?.timeIntervalSince1970
        container["sortOrder"] = sortOrder
        container["sortType"] = sortType
        container["wasDeleted"] = wasDeleted
        container["syncModified"] = syncModified
    }

    public enum Columns {
        public static let uuid = Column(CodingKeys.uuid)
        public static let name = Column(CodingKeys.name)
        public static let color = Column(CodingKeys.color)
        public static let addedDate = Column(CodingKeys.addedDate)
        public static let sortOrder = Column(CodingKeys.sortOrder)
        public static let sortType = Column(CodingKeys.sortType)
        public static let wasDeleted = Column(CodingKeys.wasDeleted)
        public static let syncModified = Column(CodingKeys.syncModified)
    }
}

extension Folder: FetchableRecord, PersistableRecord, TableRecord, Decodable {}

// This is the data side equivalent of LibrarySort
enum FolderSort: Int32 {
    case dateAddedNewestToOldest = 1, titleAtoZ = 2, episodeDateNewestToOldest = 5, custom = 6, recentlyPlayed = 7
}
