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

/// Lets a caller wait for a queued log upload to finish, keyed by the log's UUID.
final class LogUploadWaiters: @unchecked Sendable {
    static let shared = LogUploadWaiters()

    private let lock = NSLock()
    private var waiters: [String: CheckedContinuation<Bool, Never>] = [:]
    /// Results that arrived before anyone started waiting for them.
    private var results: [String: Bool] = [:]

    /// Returns `true` once the upload finishes, or `false` if it fails or doesn't finish within `timeout`.
    func wait(for uuid: String, timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            lock.lock()
            if let result = results.removeValue(forKey: uuid) {
                lock.unlock()
                continuation.resume(returning: result)
                return
            }
            waiters[uuid] = continuation
            lock.unlock()

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.resume(uuid, with: false)
            }
        }
    }

    func uploadFinished(_ uuid: String, succeeded: Bool) {
        lock.lock()
        if waiters[uuid] == nil {
            results[uuid] = succeeded
        }
        lock.unlock()
        resume(uuid, with: succeeded)
    }

    private func resume(_ uuid: String, with result: Bool) {
        lock.lock()
        let continuation = waiters.removeValue(forKey: uuid)
        lock.unlock()
        continuation?.resume(returning: result)
    }
}

extension FileLog: @retroactive EventLoggingDelegate {
    fileprivate func queueFileUpload(_ filePath: String) throws -> String {
        let logFilePath = URL(fileURLWithPath: filePath)
        let dataProvider = EventLoggingDataProvider(logUploadFile: logFilePath)
        let logFile = LogFile(url: logFilePath)
        do {
            let eventLogging = EventLogging(dataSource: dataProvider, delegate: self)
            try eventLogging.enqueueLogForUpload(log: logFile)
        } catch {
            addMessage("FileLog: failed to queue \(logFilePath.lastPathComponent) for upload: \(error)")
            throw LogError.logGenerationFailed
        }

        addMessage("FileLog: queued \(logFilePath.lastPathComponent) for upload as \(logFile.uuid)")
        return logFile.uuid
    }

    /// Queues the file for encrypted upload and waits for it to finish. Returns the log's UUID, or `nil` if it
    /// couldn't be queued, the upload failed, or it didn't finish within `timeout`.
    func uploadLog(atPath filePath: String, timeout: TimeInterval) async -> String? {
        guard let uuid = try? queueFileUpload(filePath) else {
            return nil
        }

        guard await LogUploadWaiters.shared.wait(for: uuid, timeout: timeout) else {
            addMessage("FileLog: log \(uuid) didn't finish uploading within \(Int(timeout))s")
            return nil
        }
        return uuid
    }

    /// Uploads the app's debug log and waits for it to finish, as `uploadLog(atPath:timeout:)`.
    func uploadDebugLog(timeout: TimeInterval) async -> String? {
        do {
            return await uploadLog(atPath: try await logFileForUpload(), timeout: timeout)
        } catch {
            addMessage("FileLog: failed to generate the log for upload: \(error)")
            return nil
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

    // MARK: - EventLoggingDelegate

    public var shouldUploadLogFiles: Bool {
        FileManager.default.fileExists(atPath: LogFilePaths.debugUploadLog) || FileManager.default.fileExists(atPath: LogFilePaths.watchUploadLog)
    }

    public func didFinishUploadingLog(_ log: LogFile) {
        addMessage("FileLog: uploaded log \(log.uuid)")
        LogUploadWaiters.shared.uploadFinished(log.uuid, succeeded: true)
        let filePath = log.url.absoluteString
        try? FileManager.default.removeItem(atPath: filePath)
    }

    public func uploadFailed(_ log: LogFile) {
        addMessage("FileLog: failed to upload log \(log.uuid)")
        LogUploadWaiters.shared.uploadFinished(log.uuid, succeeded: false)
        let filePath = log.url.absoluteString
        try? FileManager.default.removeItem(atPath: filePath)
    }

    public func logError(_ error: Error, userInfo: [String: Any]?) {
        addMessage("FileLog: log upload error: \(error)")
    }
}
