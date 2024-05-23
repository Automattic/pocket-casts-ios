import Foundation
import PocketCastsUtils
import XCTest

class StringExtensionTests: XCTestCase {
    // MARK: isValidEmail

    func test_isValidEmail() throws {
        // Valid Emails
        XCTAssertTrue("email@example.com".isValidEmail)
        XCTAssertTrue("firstname.lastname@example.com".isValidEmail)
        XCTAssertTrue("email@subdomain.example.com".isValidEmail)
        XCTAssertTrue("firstname+lastname@example.com".isValidEmail)
        XCTAssertTrue("email4@example.com".isValidEmail)

        // Invalid emails
        XCTAssertFalse("".isValidEmail)
        XCTAssertFalse("plainaddress".isValidEmail)
        XCTAssertFalse("@example.com".isValidEmail)
        XCTAssertFalse("email@".isValidEmail)
        XCTAssertFalse("email@example.com email@example.com".isValidEmail)
    }

    func testSnakeCased() {
        XCTAssertEqual("test", "test".lowerSnakeCased())
        XCTAssertEqual("test_snake", "testSnake".lowerSnakeCased())
        XCTAssertEqual("test_snake_case", "testSnakeCase".lowerSnakeCased())
    }
}
