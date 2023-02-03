import Foundation
import PocketCastsUtils

struct StorageManager {
    typealias Attributes = [FileAttributeKey: Any]

    private static var fileManager: FileManager = .default

    @discardableResult
    static func moveItem(at fromURL: URL, to toURL: URL, attributes: Attributes? = nil, options: Options? = nil) throws -> Bool {
        if let options, options.contains(.overwriteExisting) {
            removeItem(at: toURL)
        }

        try moveItem(at: fromURL, to: toURL)

        let attrs = (attributes ?? [:]).merging(Constants.defaultAttributes) { current, _ in current }
        setAttributes(attrs, of: toURL)

        return true
    }

    @discardableResult
    static func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: Attributes? = nil) -> Bool {
        let attrs = (attributes ?? [:]).merging(Constants.defaultAttributes) { current, _ in current }

        return tryLog(try fileManager.createDirectory(atPath: path, withIntermediateDirectories: createIntermediates, attributes: attrs), operation: "createDirectory")
    }

    @discardableResult
    static func removeItem(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path) else {
            return true
        }

        return tryLog(try fileManager.removeItem(at: url), operation: "removeItem")
    }

    @discardableResult
    static func setAttributes(_ attributes: Attributes, of url: URL) -> Bool {
        tryLog(try fileManager.setAttributes(attributes, ofItemAtPath: url.path), operation: "setAttributes")
    }

    @discardableResult
    static func updateFileProtectionToDefault(for url: URL) -> Bool {
        return setAttributes(Constants.defaultAttributes, of: url)
    }

    private static func moveItem(at fromURL: URL, to toURL: URL) throws {
        try fileManager.moveItem(at: fromURL, to: toURL)
    }

    // MARK: - Config

    struct Options: OptionSet {
        static let overwriteExisting = Options(rawValue: 1 << 0)

        let rawValue: Int
    }

    private enum Constants {
        static let defaultAttributes: Attributes = [
            .protectionKey: FileProtectionType.none
        ]
    }
}

private extension StorageManager {
    @discardableResult
    static func tryLog(_ block: @autoclosure () throws -> Void, operation: String, error handler: @autoclosure () -> ((Error) -> Void)? = nil) -> Bool {
        do {
            try block()
            return true
        } catch {
            FileLog.shared.addMessage("StorageManager[\(operation)] failed with error \(error)")
            handler()?(error)
            return false
        }
    }
}
