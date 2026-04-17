import XCTest
import AVFoundation
@testable import podcasts

final class MediaExporterResourceLoaderDelegateErrorHandlingTests: XCTestCase {

    var tempFilePath: String!

    override func setUp() {
        super.setUp()
        tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString + "_delegate_error_test.media")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tempFilePath)
        tempFilePath = nil
        super.tearDown()
    }

    // MARK: - Failure callback propagation

    func testCallback_receivesFailedStatus_whenURLSessionCompletesWithError() {
        let expectation = XCTestExpectation(description: "Callback receives .failed")
        var capturedStatus: MediaExporterResourceLoaderDelegate.FileExportStatus?

        let delegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { status, _, _, _ in
            capturedStatus = status
            expectation.fulfill()
        }

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        delegate.urlSession(.shared, task: MockURLSessionTask(), didCompleteWithError: error)

        wait(for: [expectation], timeout: 1.0)

        guard case .failed(let receivedError) = capturedStatus else {
            XCTFail("Expected .failed status, got \(String(describing: capturedStatus))")
            return
        }
        XCTAssertEqual((receivedError as NSError).code, NSURLErrorNotConnectedToInternet)
    }

    func testCallback_receivesFailedStatus_whenFileHandleUnableToOpenFile() {
        let expectation = XCTestExpectation(description: "Callback receives .failed on file error")
        var capturedStatus: MediaExporterResourceLoaderDelegate.FileExportStatus?

        let delegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { status, _, _, _ in
            capturedStatus = status
            expectation.fulfill()
        }

        let fileError = MediaFileHandleError.unableToOpenFile
        delegate.urlSession(.shared, task: MockURLSessionTask(), didCompleteWithError: fileError)

        wait(for: [expectation], timeout: 1.0)

        guard case .failed(let receivedError) = capturedStatus else {
            XCTFail("Expected .failed status, got \(String(describing: capturedStatus))")
            return
        }
        XCTAssertEqual(receivedError as? MediaFileHandleError, .unableToOpenFile)
    }

    func testCallback_receivesFailedStatus_whenReadPastEndOfFile() {
        let expectation = XCTestExpectation(description: "Callback receives .failed on end-of-file read")
        var capturedStatus: MediaExporterResourceLoaderDelegate.FileExportStatus?

        let delegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { status, _, _, _ in
            capturedStatus = status
            expectation.fulfill()
        }

        let eofError = MediaFileHandleError.tryToReadAfterEndOfFile
        delegate.urlSession(.shared, task: MockURLSessionTask(), didCompleteWithError: eofError)

        wait(for: [expectation], timeout: 1.0)

        guard case .failed(let receivedError) = capturedStatus else {
            XCTFail("Expected .failed status, got \(String(describing: capturedStatus))")
            return
        }
        XCTAssertEqual(receivedError as? MediaFileHandleError, .tryToReadAfterEndOfFile)
    }

    func testCallback_isNotCalledWithFailed_whenSessionCompletesSuccessfully() {
        // A successful completion with no buffered data and no response verification error
        // should call the callback with .completed, not .failed.
        let expectation = XCTestExpectation(description: "Callback receives .completed")
        var capturedStatus: MediaExporterResourceLoaderDelegate.FileExportStatus?

        let delegate = MediaExporterResourceLoaderDelegate(saveFilePath: tempFilePath) { status, _, _, _ in
            if case .completed = status {
                capturedStatus = status
                expectation.fulfill()
            }
        }

        let previousMinimumExpectedFileSize = MediaExporterItemConfiguration.minimumExpectedFileSize
        defer { MediaExporterItemConfiguration.minimumExpectedFileSize = previousMinimumExpectedFileSize }
        MediaExporterItemConfiguration.minimumExpectedFileSize = 0

        delegate.urlSession(.shared, task: MockURLSessionTask(), didCompleteWithError: nil)

        wait(for: [expectation], timeout: 1.0)

        guard case .completed = capturedStatus else {
            XCTFail("Expected .completed status, got \(String(describing: capturedStatus))")
            return
        }
    }
}

// MARK: - Helpers

private class MockURLSessionTask: URLSessionTask {
    override var originalRequest: URLRequest? { nil }
}
