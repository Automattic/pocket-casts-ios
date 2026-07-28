import Foundation
import OSLog

protocol PersistentTextWriting {
    func write(_ text: String)
}

struct LogFileWriter: PersistentTextWriting {

    private let targetFilePath: String
    private let encoding: String.Encoding
    private let fileManager: FileManager
    private let logger: Logger?

    init(
        writingToFileAtPath targetFilePath: String,
        encodingTextAs encoding: String.Encoding = .utf8,
        fileManager: FileManager = .default,
        loggingTo logger: Logger? = nil
    ) {
        self.encoding = encoding
        self.logger = logger
        self.fileManager = fileManager
        self.targetFilePath = targetFilePath
    }

    func write(_ text: String) {
        write(text, hasRetriedDirectoryCreation: false)
    }

    private func write(_ text: String, hasRetriedDirectoryCreation: Bool) {
        guard let fileHandle = FileHandle(forWritingAtPath: targetFilePath) else {
            do {
                try text.write(toFile: targetFilePath, atomically: true, encoding: encoding)
            }
            catch {
                handle(
                    fileHandleWriteError: error,
                    encounteredWriting: text,
                    hasRetriedDirectoryCreation: hasRetriedDirectoryCreation
                )
            }
            return
        }

        guard let encodedText = text.data(using: encoding) else {
            return
        }

        do {
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: encodedText)
        } catch {
            handle(
                fileHandleWriteError: error,
                encounteredWriting: text,
                hasRetriedDirectoryCreation: hasRetriedDirectoryCreation
            )
        }

        do {
            try fileHandle.close()
        } catch {
            logger?.warning("Failed to close file handle to file at path <\(targetFilePath)>. Must likely the handle is already closed or is not a filesystem file. Error: \(error)")
        }
    }

    private func handle(
        fileHandleWriteError: any Error,
        encounteredWriting textToWrite: String,
        hasRetriedDirectoryCreation: Bool
    ) {
        let fileHandleWriteError = fileHandleWriteError as NSError

        guard fileHandleWriteError.domain == NSCocoaErrorDomain else {
            logger?.debug("Unable to write to file. Error: \(fileHandleWriteError)")
            return
        }

        switch fileHandleWriteError.code {
        case NSFileNoSuchFileError:
            logger?.debug("Attempted to write to log file but directory structure for <\(targetFilePath)> appears not to exist. Creating it.")
            guard hasRetriedDirectoryCreation == false else {
                logger?.error("Directory creation for <\(targetFilePath)> already attempted; aborting to avoid recursion.")
                return
            }

            do {
                try createDirectoryStructure(for: targetFilePath)
                write(textToWrite, hasRetriedDirectoryCreation: true) // Error successfully addressed, retry the log write once.
            } catch {
                logger?.error("Failed to create directory structure for logs at <\(targetFilePath)>. Error: \(error)")
            }
        case NSFileWriteOutOfSpaceError:
            logger?.debug("Attempted to write to log file but disk is full. Error: \(fileHandleWriteError)")

        default:
            logger?.debug("Unable to write to file. Error: \(fileHandleWriteError)")
        }
    }

    private func createDirectoryStructure(for filePath: String) throws {
        let filePathComponents = filePath.split(separator: "/")
        let directoryPathComponenets = filePathComponents.dropLast()
        let directoryPath = directoryPathComponenets.joined(separator: "/")

        try fileManager.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
