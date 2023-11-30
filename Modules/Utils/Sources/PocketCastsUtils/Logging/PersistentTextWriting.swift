import Foundation
import OSLog

protocol PersistentTextWriting {
    func write(_ text: String)
}

struct LogFileWriter: PersistentTextWriting {

    private let targetFilePath: String
    private let encoding: String.Encoding
    private let logger: Logger?

    init(writingToFileAtPath targetFilePath: String, encodingTextAs encoding: String.Encoding = .utf8, loggingTo logger: Logger? = nil) {
        self.encoding = encoding
        self.logger = logger
        self.targetFilePath = targetFilePath
    }

    func write(_ text: String) {
        guard let encodedText = text.data(using: encoding) else {
            return
        }

        guard let fileHandle = FileHandle(forWritingAtPath: targetFilePath) else {
            do { try text.write(toFile: targetFilePath, atomically: true, encoding: encoding) }
            catch { logger?.debug("Unable to write to file. Error: \(error)") }
            return
        }

        do {
            try fileHandle.seekToEnd()
            fileHandle.write(encodedText)
        } catch {
            logger?.error("Failed to seek to end of file at path <\(targetFilePath)>. Error: \(error)")
        }

        do {
            try fileHandle.close()
        } catch {
            logger?.warning("Failed to close file handle to file at path <\(targetFilePath)>. Must likely the handle is already closed or is not a filesystem file. Error: \(error)")
        }
    }
}
