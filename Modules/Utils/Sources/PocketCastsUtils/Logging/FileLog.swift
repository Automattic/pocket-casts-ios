import Combine
import Foundation
import os

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

    #if os(watchOS)
        private let maxFileSize = 25.kilobytes
    #else
        private let maxFileSize = 100.kilobytes
    #endif

    private let bufferThreshold: UInt
    private let logPersistence: PersistentTextWriting
    private let logRotator: FileRotating
    private let logger: Logger?

    private lazy var entries: [LogEntry] = [] {
        didSet {
            if entries.count >= bufferThreshold {
                writeLogBufferToDisk()
            }
        }
    }
    private let logQueue: DispatchQueueing

    init(
        logPersistence: PersistentTextWriting,
        logRotator: FileRotating,
        writeQueue: DispatchQueueing = DispatchQueue(label: "au.com.pocketcasts.LogQueue", qos: .background),
        bufferThreshold: UInt = 100,
        loggingTo logger: Logger? = nil
    ) {
        self.logPersistence = logPersistence
        self.logRotator = logRotator
        self.logQueue = writeQueue
        self.bufferThreshold = bufferThreshold
        self.logger = logger
    }

    public func setup() {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: LogFilePaths.logDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {}
    }

    public func addMessage(_ message: String) {
        // if it's important enough to log to file, write it to the debug console as well
        logger?.log("\(message, privacy: .public)")

        entries.append(LogEntry(message))
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
        logger?.log("\(Self.self) forcibly flushing to disk.")
        writeLogBufferToDisk()
    }

    private func writeLogBufferToDisk() {
        let logTimestampFormatter = DateFormatHelper.sharedHelper.localTimeJsonDateFormatter
        let newLogChunk = entries.reduce(into: "") { resultChunk, logEntry in
            let formattedTimestamp = logTimestampFormatter.string(from: logEntry.timestamp)
            let logLine = "\(formattedTimestamp) \(logEntry.message)\n"

            resultChunk.append(logLine)
        }

        entries.removeAll(keepingCapacity: true)
        appendStringToLog(newLogChunk)
    }

    public func loadLogFileAsString(completion: @escaping (String) -> Void) {
        logQueue.async {
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

            completion("\(secondaryFileContents)\n\(mainFileContents)")
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

    private func appendStringToLog(_ logUpdate: String) {
        let trace = TraceManager.shared.beginTracing(eventName: "FILE_LOG_WRITE_MESSAGE_TO_FILE")
        logQueue.async { [logRotator, logPersistence, logUpdate, maxFileSize] in
            defer { TraceManager.shared.endTracing(trace: trace) }

            logRotator.rotateFile(ifSizeExceeds: maxFileSize)
            logPersistence.write(logUpdate)
        }
    }
}
