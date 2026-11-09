import Kingfisher
import UIKit
import XCTest
@testable import podcasts

final class ImageManagerCacheTests: XCTestCase {
    private let cache = ImageManager.shared.discoverCache
    private let key = "ImageManagerCacheTests-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        ImageManager.configureKingfisher()
    }

    override func tearDown() {
        let downsampler = DownsamplingImageProcessor(size: CGSize(width: 20, height: 20))
        cache.removeImage(forKey: key)
        cache.removeImage(forKey: key, processorIdentifier: downsampler.identifier)
        super.tearDown()
    }

    func testImageCachesShareOneMemoryStorage() {
        let caches = [
            KingfisherManager.shared.cache,
            ImageManager.shared.subscribedPodcastsCache,
            ImageManager.shared.discoverCache,
            CarPlayImageHelper.imageCache
        ]

        for cache in caches {
            XCTAssertTrue(cache.memoryStorage === caches[0].memoryStorage)
        }
    }

    func testDiskCacheKeepsDownloadedBytes() throws {
        let data = try XCTUnwrap(makeImage(size: 100).jpegData(compressionQuality: 0.3))

        retrieve(data: data, options: [.targetCache(cache), .waitForCache])

        XCTAssertEqual(try Data(contentsOf: cache.diskStorage.cacheFileURL(forKey: key)), data)
    }

    func testDiskCacheReadRunsTheRequestProcessor() throws {
        let data = try XCTUnwrap(makeImage(size: 100).jpegData(compressionQuality: 0.3))
        let downsampler = DownsamplingImageProcessor(size: CGSize(width: 20, height: 20))
        retrieve(data: data, options: [.targetCache(cache), .processor(downsampler), .waitForCache])
        cache.removeImage(forKey: key, processorIdentifier: downsampler.identifier, fromDisk: false)

        let image = retrieve(data: Data(), options: [.targetCache(cache), .processor(downsampler), .onlyFromCache])

        XCTAssertEqual(image?.cgImage?.width, 20)
    }

    @MainActor
    func testMemoryCacheHitSetsImageSynchronously() {
        let image = makeImage(size: 10)
        cache.store(image, forKey: key, toDisk: false)
        let imageView = UIImageView()

        imageView.kf.setImage(with: .provider(RawImageDataProvider(data: Data(), cacheKey: key)), options: [.targetCache(cache)])

        XCTAssertTrue(imageView.image === image)
    }

    @discardableResult
    private func retrieve(data: Data, options: KingfisherOptionsInfo) -> UIImage? {
        let done = expectation(description: "retrieved")
        var image: UIImage?
        KingfisherManager.shared.retrieveImage(with: .provider(RawImageDataProvider(data: data, cacheKey: key)), options: options) { result in
            image = try? result.get().image
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        return image
    }

    private func makeImage(size: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}
