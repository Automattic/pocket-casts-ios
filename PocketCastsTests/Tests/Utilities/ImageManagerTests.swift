import Kingfisher
import XCTest

@testable import podcasts

final class ImageManagerTests: XCTestCase {
    private var cache: ImageCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        cache = try ImageCache(name: "ImageManagerTests", cacheDirectoryURL: directory)
    }

    override func tearDown() {
        cache.clearMemoryCache()
        cache.clearDiskCache()
        cache = nil
        super.tearDown()
    }

    func testRetrieveImageFromCacheStoresDiskImageInMemory() throws {
        let url = URL(string: "https://example.com/artwork.png")!
        let key = url.cacheKey
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        try cache.diskStorage.store(value: XCTUnwrap(image.pngData()), forKey: key)
        XCTAssertNil(cache.retrieveImageInMemoryCache(forKey: key))

        let retrievedImage = ImageManager.shared.retrieveImageFromCache(url: url, cache: cache, fetchIfMissing: false)

        XCTAssertNotNil(retrievedImage)
        XCTAssertNotNil(cache.retrieveImageInMemoryCache(forKey: key))
    }

    func testRetrieveImageFromCacheRemovesCorruptDiskData() throws {
        let url = URL(string: "https://example.com/corrupt.png")!
        let key = url.cacheKey
        try cache.diskStorage.store(value: Data("not an image".utf8), forKey: key)

        let retrievedImage = ImageManager.shared.retrieveImageFromCache(url: url, cache: cache, fetchIfMissing: false)

        XCTAssertNil(retrievedImage)
        XCTAssertNil(cache.retrieveImageInMemoryCache(forKey: key))
        XCTAssertFalse(cache.diskStorage.isCached(forKey: key))
    }
}
