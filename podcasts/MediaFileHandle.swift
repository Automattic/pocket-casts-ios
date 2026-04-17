import Foundation
import PocketCastsUtils

enum MediaFileHandleError: Error {
    case unableToOpenFile
    case tryToReadAfterEndOfFile
}

/// File handle for local file operations.
final class MediaFileHandle {
    private let filePath: String
    private lazy var readHandle = FileHandle(forReadingAtPath: filePath)
    private lazy var writeHandle = FileHandle(forWritingAtPath: filePath)

    private let lock = NSLock()

    // MARK: Init

    init(filePath: String) {
        self.filePath = filePath

        if FileManager.default.fileExists(atPath: filePath) {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] already exists. A non empty file can cause unexpected behavior so we are overwriting it.")
        }
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
    }

    deinit {
        guard FileManager.default.fileExists(atPath: filePath) else { return }

        close()
    }
}

// MARK: Internal methods

extension MediaFileHandle {
    var attributes: [FileAttributeKey: Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: filePath)
        } catch let error as NSError {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] attribute error: \(error)")
        }
        return nil
    }

    var fileSize: Int {
        return attributes?[.size] as? Int ?? 0
    }

    func readData(withOffset offset: Int, forLength length: Int) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }

        guard let readHandle else {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] read handle is nil")
            throw MediaFileHandleError.unableToOpenFile
        }

        do {
            try readHandle.seek(toOffset: UInt64(offset))
        } catch {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] seek error: \(error)")
            throw error
        }

        do {
            return try readHandle.read(upToCount: length)
        } catch {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] read error: \(error)")
            throw error
        }
    }

    func append(data: Data) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let writeHandle = writeHandle else { return }

        try writeHandle.seekToEnd()

        try writeHandle.write(contentsOf: data)
    }

    func synchronize() {
        lock.lock()
        defer { lock.unlock() }

        guard let writeHandle = writeHandle else { return }

        do {
            try writeHandle.synchronize()
        } catch {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] synchronize error: \(error)")
        }
    }

    func close() {
        do {
            try readHandle?.close()
        } catch {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] read handle closing error: \(error)")
        }
        readHandle = nil
        do {
            try writeHandle?.close()
        } catch {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] write handle closing error: \(error)")
        }
        writeHandle = nil
    }

    func deleteFile() {
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch let error {
            FileLog.shared.addMessage("MediaFileHandle: File [\(filePath)] deletion error: \(error)")
        }
    }
}
