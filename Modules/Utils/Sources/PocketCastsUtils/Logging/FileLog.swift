import Combine
import Foundation
import os

public class FileLog {
    public enum LogError: Error {
        case logCanceled
        case logGenerationFailed
    }

    public static let shared = FileLog()
    private static let logger = Logger()

    #if os(watchOS)
        private let maxFileSize = 25.kilobytes
    #else
        private let maxFileSize = 100.kilobytes
    #endif

    private lazy var logDirectory: String = {
        let directory = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/debug_log")

        return directory
    }()

    private lazy var mainLogFilePath: String = logDirectory + "/main.log"

    private lazy var backupLogFilePath: String = logDirectory + "/old.log"

    public lazy var watchUploadLog: String = self.logDirectory + "/uploadWatchDebug.log"

    public lazy var debugUploadLog: String = self.logDirectory + "/uploadDebug.log"

    private let logQueue = DispatchQueue(label: "au.com.pocketcasts.LogQueue")

    public func setup() {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true, attributes: nil)
            // SJCommonUtils.setDontBackupFlag(URL(fileURLWithPath: logDirectory))
        } catch {}
    }

    public func addMessage(_ message: String?) {
        guard let message = message, message.count > 0 else { return }

        // if it's important enough to log to file, write it to the debug console as well
        Self.logger.log("\(message, privacy: .public)")
        let dateFormatter = DateFormatHelper.sharedHelper.localTimeJsonDateFormatter
        appendStringToLog("\(dateFormatter.string(from: Date())) \(message)\n")
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

    public func loadLogFileAsString(completion: @escaping (String) -> Void) {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            let mainFileContents: String
            do {
                mainFileContents = try String(contentsOfFile: self.mainLogFilePath)
            } catch {
                mainFileContents = "Main log is empty"
            }

            let secondaryFileContents: String
            do {
                secondaryFileContents = try String(contentsOfFile: self.backupLogFilePath)
            } catch {
                secondaryFileContents = ""
            }

            completion("\(secondaryFileContents)\n\(mainFileContents)")
        }
    }

    // Creates a merged file from `mainLogFilePath` and `backupLogFilePath` to be used for enquing the file upload.
    public func logFileForUpload() -> AnyPublisher<String, Error> {
        let file = debugUploadLog

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

    private func appendStringToLog(_ line: String) {
        let trace = TraceManager.shared.beginTracing(eventName: "FILE_LOG_WRITE_MESSAGE_TO_FILE")
        logQueue.async { [weak self] in
            defer { TraceManager.shared.endTracing(trace: trace) }
            guard let self = self, let dataToWrite = line.data(using: .utf8) else { return }

            let fileManager = FileManager.default
            do {
                // check that the main log file isn't too big, if it is, write it into the backup location
                if fileManager.fileExists(atPath: self.mainLogFilePath) {
                    let fileDict = try fileManager.attributesOfItem(atPath: self.mainLogFilePath)
                    let fileSizeInBytes = fileDict[.size] as? UInt64 ?? 0
                    if fileSizeInBytes > self.maxFileSize {
                        do { try fileManager.removeItem(atPath: self.backupLogFilePath) } catch {} // this one will throw if the file doesn't exist, which is perfectly fine
                        try fileManager.moveItem(atPath: self.mainLogFilePath, toPath: self.backupLogFilePath)
                    }
                }

                if let fileHandle = FileHandle(forWritingAtPath: self.mainLogFilePath) {
                    defer {
                        fileHandle.closeFile()
                    }
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(dataToWrite)
                } else {
                    try line.write(toFile: self.mainLogFilePath, atomically: true, encoding: String.Encoding.utf8)
                }
            } catch {
                print("Unable to write to file")
            }
        }
    }
}
