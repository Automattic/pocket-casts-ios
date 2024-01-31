import Combine
import Foundation
import os

actor LogBuffer {
    private let bufferThreshold: UInt

    private var logBuffer: [LogEntry] = [] {
        didSet {
            if logBuffer.count >= bufferThreshold {
                writeLogBufferToDisk()
            }
        }
    }

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
        private let maxFileSize = 25.kilobytes
    #else
        private let maxFileSize = 100.kilobytes
    #endif

    func append(_ message: String, date: Date) {
        // if it's important enough to log to file, write it to the debug console as well
        logger?.log("\(message, privacy: .public)")

        logBuffer.append(LogEntry(message, timestamp: date))
    }

    private func writeLogBufferToDisk() {
        let newLogChunk = logBuffer.sorted(by: { $0.timestamp.compare($1.timestamp) == .orderedAscending }).reduce(into: "") { resultChunk, logEntry in
            resultChunk.append("\(logEntry.formattedForLog)\n")
        }

        logBuffer.removeAll(keepingCapacity: true)
        appendStringToLog(newLogChunk)
    }

    private func appendStringToLog(_ logUpdate: String) {
        let trace = TraceManager.shared.beginTracing(eventName: "FILE_LOG_WRITE_MESSAGE_TO_FILE")
        defer { TraceManager.shared.endTracing(trace: trace) }

        logRotator.rotateFile(ifSizeExceeds: maxFileSize)
        logPersistence.write(logUpdate)
    }

    public func forceFlush() {
        guard !logBuffer.isEmpty else { return }

        logger?.debug("\(Self.self) forcibly flushing to disk.")
        writeLogBufferToDisk()
    }

    public func loadLogFileAsString() -> String {
        forceFlush()

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

public final class FileLog {
    public enum LogError: Error {
        case logCanceled
        case logGenerationFailed
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

    private var logBuffer: LogBuffer

    init(
        logPersistence: PersistentTextWriting,
        logRotator: FileRotating,
        bufferThreshold: UInt = 100,
        loggingTo logger: Logger? = nil
    ) {
        self.logBuffer = LogBuffer(logPersistence: logPersistence, logRotator: logRotator, bufferThreshold: bufferThreshold, loggingTo: logger)
    }

    public func addMessage(_ message: String, date: Date = Date()) {
        Task {
            await logBuffer.append(message, date: date)
        }
    }

    // Just a shortcut for `addMessage` to be used specifically for
    // the podcasts out of folders issue
    // By doing so it will be easier to delete those logs once the issue is
    // sorted.
    //
    // See: https://github.com/Automattic/pocket-casts-ios/issues/791
    public func foldersIssue(_ message: String?) {
        guard let message else { return }

        addMessage("[Folders] \(message)")
    }

    public func forceFlush() {
        Task {
            await logBuffer.forceFlush()
        }
    }

    public func loadLogFileAsString(completion: @escaping (String) -> Void) {
        Task {
            let log = await logBuffer.loadLogFileAsString()
            completion(log)
        }
    }

    // Creates a merged file from `mainLogFilePath` and `backupLogFilePath` to be used for enquing the file upload.
    public func logFileForUpload() -> AnyPublisher<String, Error> {
        let file = LogFilePaths.debugUploadLog

        return Future { [unowned self] promise in
            self.loadLogFileAsString { result in
                do {
                    try result.write(toFile: file, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    promise(.failure(LogError.logGenerationFailed))
                }

                promise(.success(file))
            }
        }
        .eraseToAnyPublisher()
    }
}
