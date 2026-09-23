import AVFoundation
import XCTest
@testable import podcasts

final class PlaybackStorageErrorTests: XCTestCase {

    func testCocoaOutOfSpaceErrorIsDetected() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError)

        XCTAssertTrue(error.isOutOfStorage)
    }

    func testDiskFullErrorIsDetected() {
        let error = NSError(domain: AVFoundationErrorDomain, code: AVError.Code.diskFull.rawValue)

        XCTAssertTrue(error.isOutOfStorage)
    }

    func testUnderlyingOutOfSpaceErrorIsDetected() {
        let posixError = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))
        let mediaError = NSError(domain: AVFoundationErrorDomain, code: AVError.Code.unknown.rawValue, userInfo: [NSUnderlyingErrorKey: posixError])
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSUnderlyingErrorKey: mediaError])

        XCTAssertTrue(error.isOutOfStorage)
    }

    func testNetworkErrorIsNotReportedAsOutOfStorage() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

        XCTAssertFalse(error.isOutOfStorage)
    }

    func testNotEnoughStorageDoesNotBlameTheInternetConnection() {
        let error = PlaybackManager.PlaybackError.notEnoughStorage(logMessage: nil)

        XCTAssertEqual(error.userMessage, L10n.playerErrorNotEnoughStorage)
        XCTAssertEqual(error.shortUserMessage, L10n.playerErrorShortNotEnoughStorage)
        XCTAssertNotEqual(error.userMessage, L10n.playerErrorInternetConnection)
        XCTAssertEqual(error.analyticsDetail, "not_enough_storage")
    }
}
