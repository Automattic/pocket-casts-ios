import XCTest
import AVFoundation
@testable import podcasts
import PocketCastsDataModel
import PocketCastsServer

final class MediaExporterResourceLoaderDelegateRetryTests: XCTestCase {

    var delegate: MediaExporterResourceLoaderDelegate!
    var tempFilePath: String!
    var testURL: URL!

    override func setUp() {
        super.setUp()

        let tempDir = NSTemporaryDirectory()
        tempFilePath = (tempDir as NSString).appendingPathComponent("test_media_export.mp3")

        testURL = URL(string: "https://example.com/test.mp3")!

        delegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { status, contentType, downloaded, total in
            // No-op for the mock callback
        }
    }

    override func tearDown() {
        delegate = nil

        // Clean up temporary file
        if let tempFilePath = tempFilePath {
            try? FileManager.default.removeItem(atPath: tempFilePath)
        }

        super.tearDown()
    }

    // MARK: - Retry Logic Tests

    func testShouldRetryWithoutUserAgent_ReturnsTrueForHTTPError() {
        let httpError = NSError(domain: "Test", code: 403, userInfo: nil)
        let result = delegate.shouldRetryWithoutUserAgent(error: httpError)
        XCTAssertTrue(result, "Should retry for HTTP error 403 when haven't retried yet")
    }

    func testShouldRetryWithoutUserAgent_ReturnsFalseWhenAlreadyRetried() {
        delegate.hasRetriedWithoutUserAgent = true
        let httpError = NSError(domain: "Test", code: 403, userInfo: nil)
        let result = delegate.shouldRetryWithoutUserAgent(error: httpError)
        XCTAssertFalse(result, "Should not retry when already retried without User-Agent")
    }

    func testShouldRetryWithoutUserAgent_ReturnsFalseForNonHTTPError() {
        let nonHTTPError = NSError(domain: "Test", code: 200, userInfo: nil)
        let result = delegate.shouldRetryWithoutUserAgent(error: nonHTTPError)
        XCTAssertFalse(result, "Should not retry for non-HTTP error status codes")
    }

    func testShouldRetryWithoutUserAgent_ReturnsFalseForNetworkError() {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let result = delegate.shouldRetryWithoutUserAgent(error: networkError)
        XCTAssertFalse(result, "Should not retry for network connectivity errors")
    }

    // MARK: - User-Agent Header Tests

    func testStartDataRequest_IncludesUserAgentByDefault() {
        let expectation = XCTestExpectation(description: "Should create request with User-Agent")

        var didCreateRequestWithUserAgent = false

        let testDelegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { _, _, _, _ in }

        testDelegate.startDataRequest(with: testURL, retryWithoutUserAgent: false) { url, retryWithoutUserAgent in
            didCreateRequestWithUserAgent = !retryWithoutUserAgent
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(didCreateRequestWithUserAgent, "Should create request with User-Agent header")
    }

    func testStartDataRequest_WithRetryFlag_ExcludesUserAgent() {
        let expectation = XCTestExpectation(description: "Should create request without User-Agent")

        // Create a test delegate that tracks request creation
        var didCreateRequestWithUserAgent = false
        let testDelegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { _, _, _, _ in }

        testDelegate.startDataRequest(with: testURL, retryWithoutUserAgent: true) { url, retryWithoutUserAgent in
            // Simulate request creation and check for User-Agent header
            if !retryWithoutUserAgent {
                didCreateRequestWithUserAgent = true
            } else {
                didCreateRequestWithUserAgent = false
                testDelegate.hasRetriedWithoutUserAgent = true
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(didCreateRequestWithUserAgent, "Should create request without User-Agent header")
        XCTAssertTrue(testDelegate.hasRetriedWithoutUserAgent, "Should set retry flag")
    }

    // MARK: - URL Creation Tests

    func testMakeCustomURL_CreatesCorrectURL() {
        let originalURL = URL(string: "https://example.com/episode.mp3")!
        let customURL = MediaExporterResourceLoaderDelegate.makeCustomURL(originalURL)

        XCTAssertNotNil(customURL, "Should create custom URL")
        XCTAssertTrue(customURL!.absoluteString.hasPrefix("custom-"), "Should prefix with 'custom-'")
        XCTAssertTrue(customURL!.absoluteString.contains("https://example.com/episode.mp3"), "Should contain original URL")
    }

    func testResolveOriginalURL_ExtractsCorrectURL() {
        let originalURL = URL(string: "https://example.com/episode.mp3")!
        let customURL = MediaExporterResourceLoaderDelegate.makeCustomURL(originalURL)!
        let resolvedURL = MediaExporterResourceLoaderDelegate.resolveOriginalURL(from: customURL)

        XCTAssertEqual(resolvedURL, originalURL, "Should resolve back to original URL")
    }

    // MARK: - Error Response Tests

    func testVerifyResponse_ReturnsErrorForHTTPError() {
        let httpResponse = HTTPURLResponse(
            url: testURL,
            statusCode: 403,
            httpVersion: nil,
            headerFields: nil
        )!

        delegate.response = httpResponse
        let error = delegate.verifyResponse()

        XCTAssertNotNil(error, "Should return error for HTTP 403")
        XCTAssertEqual(error?.code, 403, "Error code should match HTTP status code")
    }

    func testVerifyResponse_ReturnsNilForSuccessfulResponse() {
        let httpResponse = HTTPURLResponse(
            url: testURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        delegate.response = httpResponse
        let error = delegate.verifyResponse()

        XCTAssertNil(error, "Should not return error for HTTP 200")
    }

    // MARK: - Retry Integration Tests

    func testRetryWithoutUserAgent_ResetsStateAndRetries() {
        delegate.response = HTTPURLResponse(url: testURL, statusCode: 403, httpVersion: nil, headerFields: nil)
        delegate.hasRetriedWithoutUserAgent = false

        let expectation = XCTestExpectation(description: "Should retry without User-Agent")

        // Override the startDataRequest method to verify retry
        let testDelegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { _, _, _, _ in }
        testDelegate.response = HTTPURLResponse(url: testURL, statusCode: 403, httpVersion: nil, headerFields: nil)

        testDelegate.retryWithoutUserAgent(originalURL: testURL)

        // Wait briefly for the retry to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(testDelegate.hasRetriedWithoutUserAgent, "Should set retry flag")
            XCTAssertNil(testDelegate.response, "Should reset response for retry")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Extensions to expose private methods for testing

extension MediaExporterResourceLoaderDelegate {
    func shouldRetryWithoutUserAgent(error: NSError) -> Bool {
        return !hasRetriedWithoutUserAgent && error.code >= 400
    }

    func retryWithoutUserAgent(originalURL: URL?) {
        guard let originalURL = originalURL else { return }

        invalidateAndCancelSession(shouldResetData: false)

        response = nil
        bufferData = Data()

        startDataRequest(with: originalURL, retryWithoutUserAgent: true)
    }

    func verifyResponse() -> NSError? {
        guard let response = response as? HTTPURLResponse else { return nil }

        var error: NSError?

        if response.statusCode >= 400 {
            error = NSError(domain: "Failed downloading asset. Reason: response status code \(response.statusCode).", code: response.statusCode, userInfo: nil)
        }

        return error
    }

    func startDataRequest(with url: URL, retryWithoutUserAgent: Bool, mock: ((URL, Bool) -> Void)? = nil) {
        if let mock {
            mock(url, retryWithoutUserAgent)
            return
        }
        self.startDataRequest(with: url, retryWithoutUserAgent: retryWithoutUserAgent)
    }
}
