import Foundation
import os

public final class FileLog {
    public enum LogError: Error {
        case logCanceled
        case logGenerationFailed
    }

    /// The destinations a log message can be written to.
    public struct LogDestination: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// The rotating log file, which is what gets uploaded with support requests.
        public static let file = LogDestination(rawValue: 1 << 0)

        /// The unified logging system, visible in Console and Xcode.
        public static let console = LogDestination(rawValue: 1 << 1)

        public static let all: LogDestination = [.file, .console]
    }

    public static let shared: FileLog = {
        let logger = Logger()

        let logFileWriter = LogFileWriter(
            writingToFileAtPath: LogFilePaths.mainLogFilePath,
            loggingTo: logger
        )

        let fileRotator = FileRotator(
            targetFilePath: LogFilePaths.mainLogFilePath,
            backupFilePath: LogFilePaths.backupLogFilePath,
            loggingTo: logger
        )

        return FileLog(
            logPersistence: logFileWriter,
            logRotator: fileRotator,
            loggingTo: logger
        )
    }()

    private let logBuffer: LogBuffer
    private let logger: Logger?

    init(
        logPersistence: PersistentTextWriting,
        logRotator: FileRotating,
        bufferThreshold: UInt = 100,
        loggingTo logger: Logger? = nil
    ) {
        self.logger = logger
        self.logBuffer = LogBuffer(logPersistence: logPersistence, logRotator: logRotator, bufferThreshold: bufferThreshold, loggingTo: logger)
    }

    /// Writes the message to the given destinations.
    ///
    /// By default a message is written everywhere: if it's important enough to log to file,
    /// it's worth having in the debug console as well. Pass `.file` to opt out of the console
    /// copy when the caller already logs to the unified logging system itself.
    public func addMessage(_ message: String, date: Date = Date(), to destinations: LogDestination = .all) {
        if destinations.contains(.console) {
            logger?.log("\(message, privacy: .public)")
        }

        if destinations.contains(.file) {
            logBuffer.append(message, date: date)
        }
    }

    public func console(_ message: String) {
        logger?.log("\(message, privacy: .public)")
    }

    public func forceFlush() {
        logBuffer.flush()
    }

    public func loadLogFileAsString(completion: @escaping (String) -> Void) {
        Task {
            let log = await logBuffer.loadLogFileAsString()
            completion(log)
        }
    }

    public func logFileAsString() async -> String {
        return await logBuffer.loadLogFileAsString()
    }

    /// Creates a merged file from `mainLogFilePath` and `backupLogFilePath` to be used for enquing the file upload,
    /// returning the path it was written to.
    public func logFileForUpload() async throws -> String {
        let file = LogFilePaths.debugUploadLog
        let contents = await logBuffer.loadLogFileAsString()

        do {
            try contents.write(toFile: file, atomically: true, encoding: .utf8)
        } catch {
            throw LogError.logGenerationFailed
        }

        return file
    }
}

/// Buffers log entries in memory and writes them out in chunks once the buffer fills up.
///
/// Appending is synchronous and guarded by a lock rather than by an actor, so entries reach the
/// file in the order they were logged. Only the write itself is dispatched onto `flushQueue`,
/// which is serial, so flushes never overlap and a read always sees every preceding write.
final class LogBuffer: @unchecked Sendable {
    private let bufferThreshold: UInt

    private let entries = OSAllocatedUnfairLock(initialState: [LogEntry]())

    private let flushQueue = DispatchQueue(label: "au.com.pocketcasts.FileLogQueue")

    private let logPersistence: PersistentTextWriting
    private let logRotator: FileRotating
    private let logger: Logger?

    init(logPersistence: PersistentTextWriting,
         logRotator: FileRotating,
         bufferThreshold: UInt = 100,
         loggingTo logger: Logger? = nil) {
        self.logPersistence = logPersistence
        self.logRotator = logRotator
        self.bufferThreshold = bufferThreshold
        self.logger = logger
    }

    #if os(watchOS)
        private let maxFileSize = 65.kilobytes
    #else
        private let maxFileSize = 1.megabytes
    #endif

    func append(_ message: String, date: Date) {
        let hasReachedThreshold = entries.withLock { entries in
            entries.append(LogEntry(message, timestamp: date))
            return entries.count >= bufferThreshold
        }

        guard hasReachedThreshold else { return }

        flushQueue.async(qos: .utility) { [self] in
            writeBufferedEntriesToDisk()
        }
    }

    /// Writes the buffered entries to disk however few of them there are, blocking until that write finishes.
    func flush() {
        flushQueue.sync { [self] in
            writeBufferedEntriesToDisk(isForced: true)
        }
    }

    func loadLogFileAsString() async -> String {
        await withCheckedContinuation { continuation in
            flushQueue.async(qos: .userInitiated) { [self] in
                writeBufferedEntriesToDisk(isForced: true)
                continuation.resume(returning: readLogFiles())
            }
        }
    }

    /// Drains the buffer and appends its contents to the log file. Always called on `flushQueue`.
    private func writeBufferedEntriesToDisk(isForced: Bool = false) {
        let bufferedEntries = entries.withLock { entries in
            defer { entries.removeAll(keepingCapacity: true) }
            return entries
        }

        guard !bufferedEntries.isEmpty else { return }

        if isForced {
            logger?.debug("\(Self.self) forcibly flushing to disk.")
        }

        let newLogChunk = bufferedEntries.reduce(into: "") { resultChunk, logEntry in
            resultChunk.append("\(logEntry.formattedForLog)\n")
        }

        logRotator.rotateFile(ifSizeExceeds: maxFileSize)
        logPersistence.write(newLogChunk)
    }

    private func readLogFiles() -> String {
        let mainFileContents: String
        do {
            mainFileContents = try String(contentsOfFile: LogFilePaths.mainLogFilePath)
        } catch {
            mainFileContents = "Main log is empty"
        }

        let secondaryFileContents: String
        do {
            secondaryFileContents = try String(contentsOfFile: LogFilePaths.backupLogFilePath)
        } catch {
            secondaryFileContents = ""
        }

        return "\(secondaryFileContents)\n\(mainFileContents)"
    }
}
