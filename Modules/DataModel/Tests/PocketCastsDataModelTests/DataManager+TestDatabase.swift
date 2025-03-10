import SQLite3
import FMDB
import GRDB
import Foundation

extension FMDatabaseQueue {
    enum TestError: Error {
        case dbFolderPathFailure
    }

    static func newTestDatabase() throws -> FMDatabaseQueue? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        if !FileManager.default.fileExists(atPath: dbFolderPath as String) {
            try FileManager.default.createDirectory(atPath: dbFolderPath as String, withIntermediateDirectories: true)
        }

        let dbPath = dbFolderPath.appendingPathComponent("podcast_testDB.sqlite3")
        if FileManager.default.fileExists(atPath: dbPath) {
            try FileManager.default.removeItem(atPath: dbPath)
        }
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE
        return FMDatabaseQueue(path: dbPath, flags: flags)
    }
}

extension DatabasePool {
    enum TestError: Error {
        case dbFolderPathFailure
    }

    static func newTestDatabase() throws -> DatabasePool? {
        var config = Configuration()
        config.busyMode = .timeout(10)

        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        let dbPath = dbFolderPath.appendingPathComponent("podcast_testDB_GRDB.sqlite3")
        if FileManager.default.fileExists(atPath: dbPath) {
            try FileManager.default.removeItem(atPath: dbPath)
        }

        return try! DatabasePool(path: dbPath, configuration: config)
    }
}
