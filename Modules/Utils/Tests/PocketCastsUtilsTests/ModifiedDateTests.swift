import XCTest
@testable import PocketCastsUtils

class ModifiedDateTests: XCTestCase {
    struct TestType {
        @ModifiedDate var name: String
    }

    func testModifiedDate() throws {
        let initialName = "Hello"
        let changedName = "Changed"

        var test = TestType(name: initialName)
        XCTAssertNil(test.$name.modifiedAt, "Initial Modified Date should be nil")
        test.name = changedName
        let date = Date()
        let modifiedDate = try XCTUnwrap(test.$name.modifiedAt, "Modified Data should be set after changing value")
        XCTAssertEqual(date.timeIntervalSinceReferenceDate, modifiedDate.timeIntervalSinceReferenceDate, accuracy: 0.01, "Modified Data should be roughly equal to the current date")
    }
}
