import XCTest
@testable import podcasts

final class ImageManagerBackupTests: XCTestCase {
    func testArtworkFolderIsExcludedFromBackup() throws {
        let folder = artworkFolder(of: ImageManager.shared)

        XCTAssertTrue(folder.path.hasSuffix("Documents/artworkv3"))
        XCTAssertTrue(try isExcludedFromBackup(folder))
    }

    func testExistingArtworkFolderIsExcludedFromBackup() throws {
        var folder = artworkFolder(of: ImageManager.shared)
        var values = URLResourceValues()
        values.isExcludedFromBackup = false
        try folder.setResourceValues(values)
        XCTAssertFalse(try isExcludedFromBackup(folder))

        let manager = ImageManager()

        XCTAssertTrue(try isExcludedFromBackup(artworkFolder(of: manager)))
    }

    func testArtworkFolderStaysExcludedFromBackupAfterClearingTheCache() throws {
        let cache = ImageManager.shared.subscribedPodcastsCache
        let cleared = expectation(description: "Disk cache cleared")

        cache.clearDiskCache { cleared.fulfill() }
        wait(for: [cleared], timeout: 5)

        XCTAssertTrue(FileManager.default.fileExists(atPath: cache.diskStorage.directoryURL.path))
        XCTAssertTrue(try isExcludedFromBackup(artworkFolder(of: ImageManager.shared)))
    }

    private func artworkFolder(of manager: ImageManager) -> URL {
        manager.subscribedPodcastsCache.diskStorage.directoryURL.deletingLastPathComponent()
    }

    private func isExcludedFromBackup(_ url: URL) throws -> Bool {
        try URL(fileURLWithPath: url.path).resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true
    }
}
