import XCTest
@testable import Modules

final class ModulesTests: XCTestCase {
    func testSayHello() {
        // This test verifies the module loads and the function exists
        Modules.sayHello()
        XCTAssertTrue(true)
    }
}
