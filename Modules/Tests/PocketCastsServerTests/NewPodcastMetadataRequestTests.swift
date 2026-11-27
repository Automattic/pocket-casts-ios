@testable import PocketCastsDataModel
@testable import PocketCastsServer
@testable import PocketCastsUtils
import GRDB
import XCTest

final class NewPodcastMetadataRequestTests: XCTestCase {
    private var originalDataManager: DataManager!
    private var podcastUuid: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalDataManager = DataManager.shared
        let dbPath = NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite")
        DataManager.shared = DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: dbPath)))

        podcastUuid = UUID().uuidString.lowercased()
        MetadataURLProtocol.reset(podcastUuid: podcastUuid)
        URLProtocol.registerClass(MetadataURLProtocol.self)
    }

    override func tearDownWithError() throws {
        URLProtocol.unregisterClass(MetadataURLProtocol.self)
        try FeatureFlagOverrideStore().override(FeatureFlag.newPodcastMetadataRequest, withValue: FeatureFlag.newPodcastMetadataRequest.default)
        DataManager.shared = originalDataManager
        originalDataManager = nil

        try super.tearDownWithError()
    }

    func testFollowingAPodcastSendsNoMetadataRequest() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.newPodcastMetadataRequest, withValue: false)
        let requested = expectation(description: "metadata requested")
        requested.isInverted = true
        MetadataURLProtocol.onRequest = { requested.fulfill() }

        XCTAssertTrue(followPodcast())

        wait(for: [requested], timeout: 2)
    }

    func testFollowingAPodcastSendsAMetadataRequestForItsNewestEpisodeWhenTheFlagIsOn() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.newPodcastMetadataRequest, withValue: true)
        let requested = expectation(description: "metadata requested")
        MetadataURLProtocol.onRequest = { requested.fulfill() }

        XCTAssertTrue(followPodcast())

        wait(for: [requested], timeout: 10)
        XCTAssertEqual(MetadataURLProtocol.requestedPaths, ["/\(podcastUuid!)/2.mp3"])
    }

    private func followPodcast() -> Bool {
        let episodes: [[String: Any]] = (1...2).map { number in
            [
                "uuid": "\(podcastUuid!)-\(number)",
                "title": "Episode \(number)",
                "url": "https://pocketcasts.invalid/\(podcastUuid!)/\(number).mp3",
                "file_type": "audio/mp3",
                "published": "2026-01-0\(number)T10:00:00Z"
            ]
        }
        let podcastInfo: [String: Any] = ["podcast": ["uuid": podcastUuid!, "title": "Podcast", "episodes": episodes]]

        let added = expectation(description: "podcast added")
        var result = false
        ServerPodcastManager.shared.addFromJson(podcastUuid: podcastUuid, lastModified: nil, podcastInfo: podcastInfo, subscribe: true, autoDownloads: 0) { success in
            result = success
            added.fulfill()
        }
        wait(for: [added], timeout: 10)
        return result
    }
}

/// Answers HEAD requests for the test podcast's episode files with an empty response.
private final class MetadataURLProtocol: URLProtocol {
    nonisolated(unsafe) static var podcastUuid = ""
    nonisolated(unsafe) static var onRequest: (() -> Void)?
    nonisolated(unsafe) private(set) static var requestedPaths: [String] = []

    static func reset(podcastUuid: String) {
        self.podcastUuid = podcastUuid
        onRequest = nil
        requestedPaths = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.httpMethod == "HEAD" && request.url?.path.hasPrefix("/\(podcastUuid)/") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else { return }

        Self.requestedPaths.append(url.path)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
        Self.onRequest?()
    }

    override func stopLoading() {}
}
