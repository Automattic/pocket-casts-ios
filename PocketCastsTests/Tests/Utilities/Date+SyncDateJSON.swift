import XCTest
@testable import podcasts
import SwiftProtobuf

final class DateSyncDateJSONTest: XCTestCase {
    func testJSON() throws {
        let timestamp = SwiftProtobuf.Google_Protobuf_Timestamp(date: Date.syncDefaultDate)
        let json = try timestamp.jsonString()
        XCTAssertEqual(json, "\"1970-01-01T00:00:01Z\"", "JSON Output should match expected string")
    }
}
