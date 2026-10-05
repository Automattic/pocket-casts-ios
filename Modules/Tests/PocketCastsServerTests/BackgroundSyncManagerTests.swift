@testable import PocketCastsServer
import XCTest

final class BackgroundSyncManagerTests: XCTestCase {

    // MARK: - Download completeness check

    func testCompleteDownloadReturnsTrue() {
        XCTAssertTrue(
            BackgroundSyncManager.isDownloadComplete(receivedBytes: 1024, expectedContentLength: 1024),
            "Download with matching byte count should be considered complete"
        )
    }

    func testTruncatedDownloadReturnsFalse() {
        XCTAssertFalse(
            BackgroundSyncManager.isDownloadComplete(receivedBytes: 512, expectedContentLength: 1024),
            "Download with fewer bytes than expected should be considered truncated"
        )
    }

    func testUnknownContentLengthReturnsTrue() {
        XCTAssertTrue(
            BackgroundSyncManager.isDownloadComplete(receivedBytes: 512, expectedContentLength: BackgroundSyncManager.unknownContentLength),
            "Unknown content length should be treated as complete (can't verify)"
        )
    }

    func testZeroBytesWithExpectedContentReturnsFalse() {
        XCTAssertFalse(
            BackgroundSyncManager.isDownloadComplete(receivedBytes: 0, expectedContentLength: 100),
            "Zero bytes received when content was expected should be truncated"
        )
    }

    func testEmptyResponseMatchingExpectedReturnsTrue() {
        // Server genuinely returned 0 bytes with Content-Length: 0
        XCTAssertTrue(
            BackgroundSyncManager.isDownloadComplete(receivedBytes: 0, expectedContentLength: 0),
            "Empty response matching Content-Length: 0 should be considered complete"
        )
    }

    func testExtraBytesReturnsFalse() {
        // More bytes than expected — also suspicious
        XCTAssertFalse(
            BackgroundSyncManager.isDownloadComplete(receivedBytes: 2048, expectedContentLength: 1024),
            "More bytes than expected should be considered incomplete/corrupt"
        )
    }

    // MARK: - Up Next response processing

    private let upNextBody = Data([0x08, 0x01])

    func testUpNextResponseIsProcessedOnOK() {
        XCTAssertTrue(BackgroundSyncManager.shouldProcessUpNextResponse(httpStatus: 200, data: upNextBody))
    }

    func testUpNextResponseIsNotProcessedOnNotModified() {
        XCTAssertFalse(BackgroundSyncManager.shouldProcessUpNextResponse(httpStatus: 304, data: Data()))
    }

    func testUpNextResponseIsNotProcessedOnFailure() {
        for status in [0, 401, 500, 504] {
            XCTAssertFalse(BackgroundSyncManager.shouldProcessUpNextResponse(httpStatus: status, data: upNextBody), "status \(status)")
        }
    }

    func testUpNextResponseIsNotProcessedWhenBodyIsEmpty() {
        XCTAssertFalse(BackgroundSyncManager.shouldProcessUpNextResponse(httpStatus: 200, data: Data()))
    }

    func testUpNextResponseIsNotProcessedWhenDataIsMissing() {
        XCTAssertFalse(BackgroundSyncManager.shouldProcessUpNextResponse(httpStatus: 200, data: nil))
    }
}
