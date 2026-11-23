import Kingfisher
import UIKit
import XCTest
@testable import podcasts

final class PodcastArtworkPrefetchTests: XCTestCase {
    private var originalSessionConfiguration: URLSessionConfiguration!
    private var podcastUuid: String!

    override func setUp() {
        super.setUp()
        podcastUuid = UUID().uuidString.lowercased()
        originalSessionConfiguration = ImageDownloader.default.sessionConfiguration
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ArtworkURLProtocol.self]
        ImageDownloader.default.sessionConfiguration = configuration
    }

    override func tearDown() {
        ImageDownloader.default.sessionConfiguration = originalSessionConfiguration
        for size in PodcastThumbnailSize.allCases {
            ImageManager.shared.subscribedPodcastsCache.removeImage(forKey: ImageManager.shared.podcastUrl(imageSize: size, uuid: podcastUuid).cacheKey)
        }
        super.tearDown()
    }

    func testSavesArtworkToDiskWhenAnotherCacheHasItInMemory() {
        let url = ImageManager.shared.podcastUrl(imageSize: .list, uuid: podcastUuid)
        ImageManager.shared.discoverCache.store(ArtworkURLProtocol.image, forKey: url.cacheKey, toDisk: false)

        ImageManager.shared.cacheImages(podcastUuid: podcastUuid)

        let diskStorage = ImageManager.shared.subscribedPodcastsCache.diskStorage
        let saved = expectation(for: NSPredicate { _, _ in diskStorage.isCached(forKey: url.cacheKey) }, evaluatedWith: nil)
        wait(for: [saved], timeout: 10)
    }
}

private final class ArtworkURLProtocol: URLProtocol {
    static let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let data = Self.image.pngData(),
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "image/png"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
