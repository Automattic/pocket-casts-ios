import XCTest
@testable import PocketCastsUtils

class ModifiedDateTests: XCTestCase {
    private struct TestType {
        @ModifiedDate var name: String
    }

    private let initialName = "Initial"
    private let changedName = "Changed"

    /// Tests the initial value & unset `modifiedAt` date
    func testInitialValues() throws {
        let test = TestType(name: initialName)
        XCTAssertNil(test.$name.modifiedAt, "Initial Modified Date should be nil")
        XCTAssertEqual(test.name, initialName, "Initial Value should be \(initialName)")
    }
    
    /// Tests the `modifiedAt` update when changing value
    func testModifiedDate() throws {
        var test = TestType(name: initialName)

        test.name = changedName
        let date = Date()

        // Check value
        XCTAssertEqual(test.name, changedName, "Updated value should be \(changedName)")

        // Check modifiedAt
        let modifiedDate = try XCTUnwrap(test.$name.modifiedAt, "Modified Data should be set after changing value")
        XCTAssertEqual(date.timeIntervalSinceReferenceDate, modifiedDate.timeIntervalSinceReferenceDate, accuracy: 0.01, "Modified Data should be roughly equal to the current date")
    }
}
