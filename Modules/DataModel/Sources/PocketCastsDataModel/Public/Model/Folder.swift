import Foundation
import GRDB
import GRDBMacros

@GRDBRecord(table: "Folder")
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
    @GRDBIgnore
    public var cachedUnreadCount = 0

    override public init() {
        super.init()
    }

    func folderSort() -> FolderSort {
        FolderSort(rawValue: sortType) ?? .dateAddedNewestToOldest
    }
}

// This is the data side equivalent of LibrarySort
enum FolderSort: Int32 {
    case dateAddedNewestToOldest = 1, titleAtoZ = 2, episodeDateNewestToOldest = 5, custom = 6, recentlyPlayed = 7
}
