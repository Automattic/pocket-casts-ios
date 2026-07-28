import Foundation
@testable import PocketCastsServer
import XCTest

class UploadProgressTests: XCTestCase {
    func test_percentageProgressAsString() throws {
        var progress = UploadProgress(uploadedSoFar: 50, totalToUpload: 100, status: .notUploaded)
        XCTAssertEqual(progress.percentageProgressAsString(), "50%")

        progress = UploadProgress(uploadedSoFar: 50, totalToUpload: 0, status: .notUploaded)
        XCTAssertEqual(progress.percentageProgressAsString(), "0%")

        progress = UploadProgress(uploadedSoFar: 0, totalToUpload: 100, status: .notUploaded)
        XCTAssertEqual(progress.percentageProgressAsString(), "0%")

        progress = UploadProgress(uploadedSoFar: 0, totalToUpload: 0, status: .notUploaded)
        XCTAssertEqual(progress.percentageProgressAsString(), "0%")

        progress = UploadProgress(uploadedSoFar: 1, totalToUpload: 100, status: .notUploaded)
        XCTAssertEqual(progress.percentageProgressAsString(), "1%")

        progress = UploadProgress(uploadedSoFar: 100, totalToUpload: 100, status: .notUploaded)
        XCTAssertEqual(progress.percentageProgressAsString(), "100%")
    }
}
