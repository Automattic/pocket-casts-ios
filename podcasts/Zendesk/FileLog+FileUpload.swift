import AutomatticEncryptedLogs
import Combine
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

extension FileLog: EventLoggingDelegate {
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

    public func encryptedLogUUID() -> AnyPublisher<String, Never> {
        logFileForUpload()
            .tryMap { [unowned self] filePath in
                try self.queueFileUpload(filePath)
            }
            .replaceError(with: FileLog.genericErrorMessage)
            .eraseToAnyPublisher()
    }

    private func watchLogFileForUpload() -> AnyPublisher<String?, Never> {
        Future<String?, Error> { promise in
            WatchManager.shared.requestLogFile { watchLog in
                guard let wearableLog = watchLog else {
                    promise(.success(nil))
                    return
                }
                let file = LogFilePaths.watchUploadLog
                do {
                    try wearableLog.write(toFile: file, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    promise(.failure(LogError.logGenerationFailed))
                }

                promise(.success(file))
            }
        }
        .replaceError(with: FileLog.genericErrorMessage)
        .eraseToAnyPublisher()
    }

    public func encryptedWatchLogUUID() -> AnyPublisher<String, Never> {
        watchLogFileForUpload()
            .tryMap { [unowned self] filePath in
                guard let filePath = filePath else {
                    return Self.noWearableLogsAvailable
                }

                return try self.queueFileUpload(filePath)
            }
            .replaceError(with: FileLog.genericErrorMessage)
            .eraseToAnyPublisher()
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
