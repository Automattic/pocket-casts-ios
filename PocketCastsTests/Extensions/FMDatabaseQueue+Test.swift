import SQLite3
import FMDB
import GRDB
import Foundation
@testable import PocketCastsDataModel
import PocketCastsUtils

extension FMDatabaseQueue {
    enum TestError: Error {
        case dbFolderPathFailure
    }

    static func newTestDatabase(databaseName: String? = nil) throws -> FMDatabaseQueue? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        if !FileManager.default.fileExists(atPath: dbFolderPath as String) {
            try FileManager.default.createDirectory(atPath: dbFolderPath as String, withIntermediateDirectories: true)
        }

        let dbPath = dbFolderPath.appendingPathComponent(databaseName ?? "podcast_testDB.sqlite3")
        if databaseName == nil && FileManager.default.fileExists(atPath: dbPath) {
            try FileManager.default.removeItem(atPath: dbPath)
        }
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE
        return FMDatabaseQueue(path: dbPath, flags: flags)
    }

    static func copyDatabase(toFile: String) throws {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        if !FileManager.default.fileExists(atPath: dbFolderPath as String) {
            try FileManager.default.createDirectory(atPath: dbFolderPath as String, withIntermediateDirectories: true)
        }

        let dbPath = dbFolderPath.appendingPathComponent("podcast_testDB.sqlite3")
        if FileManager.default.fileExists(atPath: dbPath) {
            if FileManager.default.fileExists(atPath: dbFolderPath.appendingPathComponent(toFile)) {
                try FileManager.default.removeItem(atPath: dbFolderPath.appendingPathComponent(toFile))
            }

            try FileManager.default.copyItem(at: URL(fileURLWithPath: dbPath), to: URL(fileURLWithPath: dbFolderPath.appendingPathComponent(toFile)))
        }
    }
}

extension DatabasePool {
    enum TestError: Error {
        case dbFolderPathFailure
    }

    static var currentDatabasePool: DatabasePool?

    static func newTestDatabase(databaseName: String? = nil) throws -> DatabasePool? {
        var config = Configuration()
        config.busyMode = .timeout(10)

        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        if !FileManager.default.fileExists(atPath: dbFolderPath as String) {
            try FileManager.default.createDirectory(atPath: dbFolderPath as String, withIntermediateDirectories: true)
        }

        let dbPath = dbFolderPath.appendingPathComponent(databaseName ?? "podcast_testDB_GRDB.sqlite3")
        if databaseName == nil && FileManager.default.fileExists(atPath: dbPath) {
            try FileManager.default.removeItem(atPath: dbPath)
        }

        // Close any previous connection
        try! currentDatabasePool?.close()

        currentDatabasePool = try! DatabasePool(path: dbPath, configuration: config)

        return currentDatabasePool!
    }

    static func copyDatabase(toFile: String) throws {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last as NSString?
        guard let dbFolderPath = documentsPath?.appendingPathComponent("Pocket Casts") as? NSString else {
            throw TestError.dbFolderPathFailure
        }

        if !FileManager.default.fileExists(atPath: dbFolderPath as String) {
            try FileManager.default.createDirectory(atPath: dbFolderPath as String, withIntermediateDirectories: true)
        }

        let dbPath = dbFolderPath.appendingPathComponent("podcast_testDB_GRDB.sqlite3")
        if FileManager.default.fileExists(atPath: dbPath) {
            if FileManager.default.fileExists(atPath: dbFolderPath.appendingPathComponent(toFile)) {
                try FileManager.default.removeItem(atPath: dbFolderPath.appendingPathComponent(toFile))
            }

            try FileManager.default.copyItem(at: URL(fileURLWithPath: dbPath), to: URL(fileURLWithPath: dbFolderPath.appendingPathComponent(toFile)))
        }
    }
}

extension DataManager {
    static func newTestDataManager() -> DataManager {
        try! FeatureFlag.grdb.enabled ? DataManager(dbQueue: GRDBQueue(dbPool: DatabasePool.newTestDatabase()!)) : DataManager(dbQueue: FMDBQueue(fmdbQueue: FMDatabaseQueue.newTestDatabase()!))
    }
}
