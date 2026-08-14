import AutomatticEncryptedLogs
import Foundation
import PocketCastsUtils
import SwiftUI

struct EventLoggingDataProvider: EventLoggingDataSource {
    let loggingEncryptionKey = ApiCredentials.loggingEncryptionKey
    let loggingAuthenticationToken = ApiCredentials.dotcomSecret
    let logUploadFile: URL?

    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL? {
        logUploadFile
    }
}

extension FileLog: @retroactive EventLoggingDelegate {
    static let genericErrorMessage = "No log file uploaded: Error generating logs"

    static let noWearableLogsAvailable = "No wearable logs were available"

    fileprivate func queueFileUpload(_ filePath: String) throws -> String {
        let logFilePath = URL(fileURLWithPath: filePath)
        let dataProvider = EventLoggingDataProvider(logUploadFile: logFilePath)
        let logFile = LogFile(url: logFilePath)
        do {
            let eventLogging = EventLogging(dataSource: dataProvider, delegate: self)
            try eventLogging.enqueueLogForUpload(log: logFile)
        } catch {
            throw LogError.logGenerationFailed
        }

        return logFile.uuid
    }

    public func encryptedLogUUID() async -> String {
        do {
            return try queueFileUpload(try await logFileForUpload())
        } catch {
            return FileLog.genericErrorMessage
        }
    }

    /// Writes the watchOS log to a file to be enqueued for upload, returning the path it was written
    /// to, or `nil` if the watch had no logs to give.
    func watchLogFileForUpload() async throws -> String? {
        guard let wearableLog = await WatchManager.shared.requestLogFile() else {
            return nil
        }

        let file = LogFilePaths.watchUploadLog
        do {
            try wearableLog.write(toFile: file, atomically: true, encoding: .utf8)
        } catch {
            throw LogError.logGenerationFailed
        }

        return file
    }

    /// Returns the watchOS log contents as a string, using the same flow as support uploads
    func watchLogFileAsString() async -> String? {
        await WatchManager.shared.requestLogFile()
    }

    public func encryptedWatchLogUUID() async -> String {
        do {
            guard let filePath = try await watchLogFileForUpload() else {
                return Self.noWearableLogsAvailable
            }

            return try queueFileUpload(filePath)
        } catch {
            return FileLog.genericErrorMessage
        }
    }

    // MARK: - EventLoggingDelegate

    public var shouldUploadLogFiles: Bool {
        FileManager.default.fileExists(atPath: LogFilePaths.debugUploadLog) || FileManager.default.fileExists(atPath: LogFilePaths.watchUploadLog)
    }

    public func didFinishUploadingLog(_ log: LogFile) {
        let filePath = log.url.absoluteString
        try? FileManager.default.removeItem(atPath: filePath)
    }

    public func uploadFailed(_ log: LogFile) {
        let filePath = log.url.absoluteString
        try? FileManager.default.removeItem(atPath: filePath)
    }

    public func logError(_ error: Error, userInfo: [String: Any]?) {}
}
