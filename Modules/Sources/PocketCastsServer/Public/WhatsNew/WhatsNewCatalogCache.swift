import Foundation
import PocketCastsUtils

/// Keeps the last successfully fetched What's New catalog on disk so the feed works offline.
public struct WhatsNewCatalogCache {
    private let directory: URL

    public init(directory: URL = WhatsNewCatalogCache.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        URL.cachesDirectory.appending(path: "whats-new", directoryHint: .isDirectory)
    }

    public func data(forLocale locale: String) -> Data? {
        try? Data(contentsOf: fileURL(forLocale: locale))
    }

    public func save(_ data: Data, forLocale locale: String) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(forLocale: locale), options: .atomic)
        } catch {
            FileLog.shared.addMessage("What's New: failed to cache the catalog: \(error.localizedDescription)")
        }
    }

    private func fileURL(forLocale locale: String) -> URL {
        directory.appending(path: "catalog-\(locale).json")
    }
}
