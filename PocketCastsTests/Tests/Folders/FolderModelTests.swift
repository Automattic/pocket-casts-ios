import XCTest

@testable import podcasts

class FolderModelTests: XCTestCase {
    func testCapFolderNameAt100Chars() {
        let model = FolderModel()

        model.validateFolderName("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis et sapien nunc. In et ultrices dui. Aenean feugiat imperdiet orci,")

        XCTAssertEqual(model.name.count, 100)
        XCTAssertEqual(model.name, "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis et sapien nunc. In et ultrices dui. Ae")
    }

    func testDoNotChangeNamesWithLessThan100Chars() {
        let model = FolderModel()
        model.name = "Smaller name"

        model.validateFolderName("Smaller name")

        XCTAssertEqual(model.name.count, 12)
        XCTAssertEqual(model.name, "Smaller name")
    }
}
